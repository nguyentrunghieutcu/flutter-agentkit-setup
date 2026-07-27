# Project Snippets

Add snippets only after extracting a pattern from production code in this
project and validating it with the normal analysis/tests.

Do not keep generic auth, retry, Provider base-class, or API envelope snippets:
those patterns depend on the project's actual client construction, state
ownership, error contract, and backend authentication.
