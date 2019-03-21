function [cost, grad_cost] = open_generate_code(build_config, constraints, u, p, phi)
[cost, grad_cost] = casadi_codegen(u, p, phi);
clean_destination(build_config)
open_generate_cargo(build_config);
codegen_head(build_config);

main_file = fullfile(build_config.build_path, build_config.build_name, 'src', 'main.rs');
fid_main = fopen(main_file, 'a+');

codegen_const(fid_main, build_config, u, p);
copy_into_main(fid_main, fullfile(matlab_open_root, 'matlab', ...
    'private', 'codegen_get_cache.txt'));
copy_into_main(fid_main, fullfile(matlab_open_root, 'matlab', ...
    'private', 'codegen_main_fn_def.txt'));
main1(fid_main, build_config);
copy_into_main(fid_main, fullfile(matlab_open_root, 'matlab', ...
    'private', 'codegen_main_2.txt'));
open_impose_bounds(fid_main, constraints)
copy_into_main(fid_main, fullfile(matlab_open_root, 'matlab', ...
    'private', 'codegen_main_3.txt'));
fclose(fid_main);

build_autogenerated_project(build_config);



% -------------------------------------------------------------------------


function [cost, grad_cost] = casadi_codegen(u,p,phi)
[cost, grad_cost] = casadi_generate_c_code(u, p, phi);
current_dir = pwd();
cd(fullfile(matlab_open_root(), 'icasadi'));
cd(current_dir);
system('cargo build'); % builds casadi




function open_impose_bounds(fid_main, constraints)
switch constraints.get_type()
    case 'ball'
        cstr_params = constraints.get_params();
        if ~(isfield(cstr_params, 'centre') && isempty(cstr_params.centre))
            fprintf(fid_main, '\n\t\tlet bounds = Ball2::new_at_origin_with_radius(%f);\n', cstr_params.radius);
        end
    case 'no_constraints'
        fprintf(fid_main, '\n\t\tlet bounds = NoConstraints::new();\n');
    otherwise
        fprintf(fid_main, '\n\t\tlet bounds = NoConstraints::new();\n');
end



function main1(fid_main, build_config)
fprintf(fid_main, '\n\tlet socket = UdpSocket::bind("%s:%d").expect("could not bind to address");\n', ...
    build_config.udp_interface.bind_address, build_config.udp_interface.port);
fprintf(fid_main, '\tsocket.set_read_timeout(None).expect("set_read_timeout failed");\n');
fprintf(fid_main, '\tsocket.set_write_timeout(None).expect("set_write_timeout failed");\n');    
fprintf(fid_main, '\tprintln!("Server started and listening at %s:%d");\n', ...
    build_config.udp_interface.bind_address, build_config.udp_interface.port);

function copy_into_main(fid_main, other_file)
fid_other = fopen(other_file, 'r');
fwrite(fid_main, fread(fid_other));
fclose(fid_other);


function codegen_const(fid_main, build_config, u, p)
fprintf(fid_main, '\nconst TOLERANCE: f64 = %g;\n', build_config.solver.tolerance);
fprintf(fid_main, 'const LBFGS_MEMORY: usize = %d;\n', build_config.solver.lbfgs_mem);
fprintf(fid_main, 'const MAX_ITERS: usize = %d;\n', build_config.solver.max_iters);
fprintf(fid_main, 'const NU: usize = %d;\n', length(u));
fprintf(fid_main, 'const NP: usize = %d;\n\n', length(p));
fprintf(fid_main, 'const COMMUNICATION_BUFFER: usize = %d;\n\n', build_config.communication_buffer_size);

function codegen_head(build_config)
head_file_path = fullfile(matlab_open_root, 'matlab', 'private', 'codegen_head.txt');
main_file = fullfile(build_config.build_path, build_config.build_name, 'src', 'main.rs');
copyfile(head_file_path, main_file);



function clean_destination(build_config)
destination_dir = fullfile(build_config.build_path, build_config.build_name);
if ~exist(destination_dir, 'dir')
    mkdir(destination_dir,'s');
    init_cargo(build_config);
end


function open_generate_cargo(build_config)
cargo_file_name = 'Cargo.toml';
cargo_file_path = fullfile(build_config.build_path, ...
    build_config.build_name, cargo_file_name);
fid_cargo = fopen(cargo_file_path, 'w');

fprintf(fid_cargo, '[package]\nname = "%s"\n', build_config.build_name);
fprintf(fid_cargo, 'version = "%s"\n', build_config.version);
fprintf(fid_cargo, 'license = "%s"\n', build_config.license);
fprintf(fid_cargo, 'authors = [');
for i=1:length(build_config.authors)-1
    fprintf(fid_cargo, '"%s", ', build_config.authors{i});
end
fprintf(fid_cargo, '"%s"]\n', build_config.authors{end});
fprintf(fid_cargo, 'edition = "2018"\n');

fprintf(fid_cargo, '\n\n[dependencies]\noptimization_engine = {path = "../../"}\n');
fprintf(fid_cargo, 'icasadi = {path = "../../icasadi/"}\nserde = { version = "1.0", features = ["derive"] }\n');
fprintf(fid_cargo, 'serde_json = "1.0"\n');

fclose(fid_cargo);



function init_cargo(build_config)
current_path = pwd();
cd(fullfile(build_config.build_path, build_config.build_name));
system('cargo init');
cd(current_path);



function build_autogenerated_project(build_config)
current_path = pwd();
destination_path = fullfile(build_config.build_path, build_config.build_name);
cd(destination_path);
build_cmd = 'cargo build';
if ~isempty(build_config.target) && strcmp(build_config.target, 'rpi')
    fprintf('[codegen] Setting target: arm-unknown-linux-gnueabihf (ARMv6/Raspberry Pi)\n');
    build_config.target = 'arm-unknown-linux-gnueabihf';
end
if ~isempty(build_config.target) && ~strcmp(build_config.target, 'default')
    build_cmd = strcat(build_cmd, ' --target=', build_config.target);
end
if ~isempty(build_config.build_mode) && strcmp(build_config.build_mode, 'release')
    build_cmd = strcat(build_cmd, ' --release');
end
fprintf('[codegen] Build command: %s\n', build_cmd);
system(build_cmd);
cd(current_path);