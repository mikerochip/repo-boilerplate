Do this when you need to install and setup P4V on a new machine, or when you want to redo your P4V install.

1. Download https://www.perforce.com/downloads/helix-visual-client-p4v
   1. Windows: Check all utilities after running the installer (p4cli, p4admin, etc)
   1. Mac: Additionally [download this](https://www.perforce.com/downloads/helix-command-line-client-p4) then [do this](https://www.perforce.com/manuals/p4guide/Content/P4Guide/install.unix.html)
1. You'll need to create a workspace after running the installer (if you haven't already)
1. Name your workspaces like this: ```<ComputerName>_<RepoName>```, for example: ```MSCHW-PC1_MyRepo```
1. Open a terminal
1. ```p4 set P4CONFIG=.p4config```
1. ```p4 set P4IGNORE=.p4ignore```
1. Restart all open terminals
1. **For each workspace**, create a ```.p4config``` file at the workspace root with these contents
```
P4CLIENT=<WorkspaceName>
P4USER=<CorpUsername>
P4PORT=<P4ServerAddress>:1666
P4IGNORE=.p4ignore
```
