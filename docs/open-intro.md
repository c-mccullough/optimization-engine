---
id: open-intro
title: Optimization Engine
sidebar_label: Introduction
---

<script type="text/x-mathjax-config">MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});</script>
<script type="text/javascript" src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>

## What is Optimization Engine (OpEn)?

Embedded optimization is of great importance in a wide range of engineering applications. For example, **model predictive control** is becoming all the more popular in highly dynamical systems with sampling times of a few milliseconds. 

Relevant application domains include

- **fast robotic systems** which are often controlled by optimization-based methodologies,
- **autonomous vehicles** where the collision avoidance problem is stated as a nonconvex optimization problem,
- **autonomous UAVs** which have very tight runtime requirements

to name a few.

<img src="/optimization-engine/img/open-functionality.jpg" alt="OpEn functionality" />

**Optimization Engine** (OpEn) is a framework that allows engineers to **design** and **embed** optimization-based control and monitoring modules on such autonomous highly dynamical systems.

The aim of **Optimization Engine** is to become a widely used software solution, which stands up to the high performance requirements of modern cyber-physical systems, runs **fast**, makes good use of the available computation **resources** (CPU, RAM), is **reliable** and has **fully predictable behavior**.

**Optimization Engine** is easy to use and fully documented. Users can either work with the engine directly (in Rust), or interface it via other languages such as Python and MATLAB.

Users can, for example, do their design entirely in Python and then use the **Optimization Engine Interface** to automatically generate Rust code (which can be used on an embedded device).


## What problems can OpEn solve?

OpEn solves parametric nonconvex optimization problems of the form

<div class="math">
\[\begin{split}\mathbb{P}(p) {}:{} \operatorname*{Minimize}_{u {}\in{} \mathbb{R}^{n_u}}&amp;\ \ f(u, p)\\
\mathrm{subject\ to}\ \  &amp;u \in U\\
&amp; F_1(u, p) \in C\\
&amp; F_2(u, p) = 0\end{split}\]</div>

where $u\in\mathbb{R}^{n_u}$ is the vector decision variables of the problem and 
$p\in\mathbb{R}^{n_p}$ is a vector of parameters.

This is a very flexible problem formulation that allows the user to model a very broad 
class of optimization problems.

In particular,
- $f:\mathbb{R}^{n_u}\times\mathbb{R}^{n_p}\to\mathbb{R}$ is a smooth ($\mathcal{C}^{1,1}$-function).
  Function $f$ can be nonconvex.
- $U\subseteq\mathbb{R}^{n_u}$ is a closed, possibly nonconvex set, on which we 
  can compute projections. Examples, include norm balls, rectangles, 
  finite sets and a lot more.
- $F_1:\mathbb{R}^{n_u}\times\mathbb{R}^{n_p}\to\mathbb{R}^{n_1}$ is a smooth mapping and 
  $C\subseteq\mathbb{R}^{n_1}$ is a closed, convex set, from which we can compute 
  distances. Examples, are: (i) the positive orthant, (ii) norm balls, and (iii)
  second-order cones.
- $F_2:\mathbb{R}^{n_u}\times\mathbb{R}^{n_p}\to\mathbb{R}^{n_2}$ is a smooth mapping

We will explain the difference between the constraints $F_1(u, p) \in C$ and 
$F_2(u, p) = 0$ below.

The user provides the problem data and OpEn **generates code** for a parametric 
optimizer where the user can pass a value $p$ and obtain a solution $u^\star$
(more on that later).


## What are some practical examples?

OpEn can solve problems of the form $\mathbb{P}(p)$ given above. A few examples
of problems that can be modelled this way are

- Nonlinear optimal control problems with applications in nonlinear model 
  predictive control (MPC) and MPC problems with nonconvex constraints (e.g., 
  obstacle avoidance problems)
- Nonlinear estimation formulations using nonlinear moving horizon estimation
- Mixed integer problems
- Nonconvex conic optimization problems
- Bilinear problems and optimization problems with complementarity constraints


**Note:** OpEn solves the optimality conditions of given nonconvex optimization problems. 
It cannot guarantee that the solutions will be global. 

## What can OpEn do?
**Optimization Engine** can be embedded on simple hardware devices and provide autonomy and reliability while it boosts the system's performance. 

Here is a lab demonstration of Optimization Engine in action. 

![Aerial Navigation Video](/optimization-engine/img/e8f236af8d38.gif)



In this video we demonstrate that **Optimization Engine** can solve an obstacle avoidance problem as fast as 20 times per second.


## How does it work?

### The power of Rust

Rust is exactly the right language for making efficient and reliable software. It combines high-level abstractions with low-level authority on the system without the need for a garbage collector or complex memory management. 

Most importantly, Rust is memory-safe and thread-safe by design! If something can go wrong during runtime, the software won't compile!

Rust compiles into llvm instructions and can run on any device, including embedded devices (such as ARM-based platforms, e.g., Raspberry Pi).


### The power of PANOC
What makes OpEn so fast?

The typical approach for solving nonconvex optimization problems in real time is the use of *Sequential Quadratic Programming* (SQP). At every iteration, SQP approximates the given nonconvex problem by a Quadratic Program. This is its main drawback: it necessitates inner iterative procedures, which will perform poorly especially when the problem at hand is ill-conditioned. The same holds for *interior point methods* - they require heavyweight inner iteration procedures.

**OpEn** uses the proximal averaged Newton-type method (PANOC) which uses the same oracle as the projected gradient method, therefore, it involves only simple iterations. PANOC is a line-search method that combines forward-backward iterations with fast Newton-type steps over the *forward-backward envelope* - a real-valued continuous and exact merit function. 

This way, **OpEn** enables very fast convergence (up to *superlinear convergence*, under mild assumptions), while it features very simple iterations which involve access to first-order information of the cost function and low-cost linear algebra (only vector-vector operations).

The result is a simple, yet rapidly convergent algorithm, which is perfectly suitable for embedded applications.

Find out more about PANOC in the [original publication](https://arxiv.org/pdf/1709.06487.pdf). See PANOC in action in obstacle avoidance scenarios in [this paper](https://core.ac.uk/download/pdf/153430972.pdf) and [this paper](https://arxiv.org/pdf/1812.04755.pdf).


### Augmented Lagrangian and Penalty Methods

PANOC can solve problems that involve a smooth cost function, $f(u,p)$ and simple
constraints of the form $u\in U$, where $U$ is a set on which we can compute
projections. In order to solve problems with more complex constraints such as 
$F_1(u, p)\in C$ or $F_2(u, p) = 0$, we resort to the augmented Lagrangian and 
penalty methods respectively.

Essentially, PANOC solves a simple "inner problem", while it is wrapped in an outer loop
which takes care of the satisfaction of these constraints. For technical details, the 
reader may refer to [this page](./algorithm).




## The structure of OpEn
**Optimization Engine** is a framework which comprises several components and layers.

All numerical routines are written in Rust, but users can design their optimizers in Python or MATLAB.

A code generation tool will create Rust code which can be used for maximum efficiency and can be uploaded on embedded devices.

**OpEn** comprises the following components:

- In Rust: the [`optimization-engine`] crate (downloaded automatically when using the 
  Python/MATLAB interfaces)
- In [Python](./python-interface) and [MATLAB](./matlab-interface): 
  code generation libraries and interfaces 

## Next steps
First, you need to [install rust]. Then, you can either learn how to use [OpEn in rust]./openrust-basic, or how to generate and use parametric optimizers [from MATLAB](./matlab-interface) or [Python](./python-interface).


[`optimization-engine`]: https://crates.io/crates/optimization_engine
[install rust]: ./installation
[OpEn in rust]: ./openrust-basic