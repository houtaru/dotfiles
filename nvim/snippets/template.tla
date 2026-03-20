---- MODULE {{MODULE}} ----
\* {{FILE}} — {{AUTHOR}}
\* Created: {{DATE}}

EXTENDS Integers, Sequences, TLC

CONSTANTS
    \* TODO: define constants

VARIABLES
    \* TODO: define variables

vars == << >>  \* TODO: list variables

TypeInvariant ==
    TRUE  \* TODO: define type invariant

Init ==
    TRUE  \* TODO: define initial state

Next ==
    UNCHANGED vars  \* TODO: define transitions

Spec == Init /\ [][Next]_vars

{{CURSOR}}
====
