# unflab

The `unflab` command: a short shell script that re-runs the install line
for you.

    unflab <utility>              install another
    unflab --uninstall <utility>  remove one
    unflab --list                 see what there is
    unflab --info <utility>       show a utility's page

It runs this, and only this:

    curl -fsSL https://unflab.app/get | sh -s -- "$@"

It keeps no database, tracks no state and updates nothing in the
background. `get` installs it the first time it installs something else,
unless you pass `--no-helper`. If you'd rather not have it, run
`unflab --uninstall unflab`; the curl line still works on its own.
