[![Build status](https://github.com/peal/vole/workflows/CI/badge.svg?branch=master)](https://github.com/peal/vole/actions?query=workflow%3ACI+branch%3Amaster)
[![Code coverage](https://codecov.io/gh/peal/vole/branch/master/graph/badge.svg?token=k6B5xmbzc4)](https://codecov.io/gh/peal/vole)

# rust-vole / [The GAP package Vole](https://peal.github.io/vole/)

> An implementation of fundamental group theory algorithms in Rust


This software aims to implement some highly efficient backtrack search algorithms in finite permutation groups.
These algorithms are intended to solve a range of problems, including (but not limited to):

* Subgroup intersection
* Normaliser
* Centraliser
* Graph isomorphism
* Coset intersection
* Canonical image

These algorithms are based on the theory introduced by the paper
“[Permutation group algorithms based on directed graphs](https://doi.org/10.1016/j.jalgebra.2021.06.015)” (2021),
by Christopher Jefferson, Markus Pfeiffer, Rebecca Waldecker, and Wilf A. Wilson.
This theory extends the well-established “partition backtrack” framework of Jeffrey Leon,
and works with labelled digraphs as the fundamental objects of these algorithms.


## Contact

The authors of this software are Mun See Chang,
[Christopher Jefferson](https://caj.host.cs.st-andrews.ac.uk),
and [Wilf A. Wilson](https://wilf.me).

If you encounter a problem with this software, or if you have specific suggestions, then [please create an issue on our GitHub issue tracker](https://github.com/peal/vole/issues), or get in touch with us by other means.
The authors can be contacted directly via the information given on their webpages, or the information given on the title page of the GAP package's manual.


## License

This software is licensed under the
[Mozilla Public License, Version 2.0](https://www.mozilla.org/en-US/MPL/2.0).
