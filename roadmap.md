Roadmap for Rust-Peal
=====================

"Basic" Permutation Algorithms
------------------------------

* All functions should be:
  * Tested, preferably with randomly generated input (groups may be read from a database)
  * Benchmarked (once again, over many groups)

- Top quality implementations of the most basic permutation group techniques:
   - Orbit of a single point
   - Orbits of all points
   - Single minimal block structures
   - All block structures
   - Find one / all / non-trivial orbital graphs
   - Random replacement algorithm to get random elements

- Represent Stabilizer chains
  - Schreier Vector
  - Strip
  - Check membership
  - Random element of group

- Build stabilizer chains
  - From a base + strong generating set
  - With random algorithm
  - With "standard" multiplier algorithm


Backtracking
------------

* Group intersection


* Canonical Images
    - In Symmetric Group
    - In a named group
