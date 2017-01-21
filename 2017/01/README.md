# October 2016 - Git

## What is Git?

- Git is a [Distributed Version-Control System](https://en.wikipedia.org/wiki/Distributed_version_control) (DVCS), in contrast with CVCS (Centralized VCS) like CVS, SVN, etc.
  - No central server for each checkout/checkin of code
  - Changes to the repository (commits, etc.) happen offline (not online), and can be pushed/pulled to/from other repositories
- Each update to the repository represents the entire contents of the repository at the time that change was made
  - Most CVCS maintain a separate history and revision number/ID for each tracked file
  - No separate history for each file in Git
- Each update is identified by taking the changes made, along with a bunch of metadata including the commit message, the name and email of the author(s) of the commit, the timestamp, the parent(s), etc. and hashing it using SHA1. This hash is known as the commit ID (or just the "SHA").
- Changes to a git repository can be represented using a [directed acyclic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph) (DAG)
  - Each commit has at least one parent
  - Git merges have two parents

## Configuring Git

Git configuration is managed using the ``git config`` command. Both global configuration and local configuration settings are supported. Global settings end up in ``~/.gitconfig``, while local configuration goes in ``$REPO/.git/config``, where ``$REPO`` refers to the location of the git repository.

The first thing you should do is set a global ``user.name`` and ``user.email``. These two settings are required to commit changes to a repo. If either of these are missing , a ``git commit`` command will fail with a message telling you to set these config values.

```bash
$ git config --global user.name 'Firstname Lastname'
$ git config --global user.email myaddress@domain.tld
```

To set a specific ``user.name`` and/or ``user.email`` for a specific git repository, just run the ``git config`` command from within the git repository, and leave off the ``--global``:

```bash
$ git config user.name 'Charlie Root'
$ git config user.email foo@bar.com
```

To list all config options, use ``git config --list``. If this command is executed outside of a git repository, it will show you the global config settings. If executed from within a git repository, it will show the global configuration followed by the local configuration. If you have a local ``user.email`` that differs from the global one, then both will show up in a ``git config --list``, but the last one displayed will be the one that is the effective value for that config option.

```bash
$ git config --list | fgrep user.email
user.email=myaddress@domain.tld
user.email=foo@bar.com
```

When in doubt, using ``git config --get <option_name>`` will tell you the effective config value:

```bash
$ git config --get user.email
foo@bar.com
```

See ``man git-config`` for a comprehensive list of config options (there are a lot!).

## Creating a new repo

### Initialize the repo

```bash
# First method (create repo dir first)
$ mkdir myrepo
$ cd myrepo
$ git init

# Second method (create repo dir and initialize in one step)
$ git init myrepo
```

The first method is also useful for cases where you've begun editing files before you initialize. A ``git init`` isn't just for empty dirs.

### Add some files

```bash
$ cat <<EOF >foo.txt
Hello world!
EOF
$ cat <<EOF >bar.txt
This is another file
EOF
```

### Tell Git to track these files

```bash
$ git add .
```

This is called "staging". You can stage individual files, but using the ``.`` simply tells git to stage everything recursively down from the current directory. Staging can also be performed on files which are already being tracked by Git, more on that below.

### Commit your changes

```bash
$ git commit
```

This will launch a text editor where you can write a message explaining what you are doing with this commit. Git commit messages contain a summary, as well as an optional descriptive paragraph (or more) which goes into greater detail. A good summary line is 50 characters or less, with additional info coming in the description. To distiguish a summary from the description, separate them with a blank line.

It is also possible to commit without launching an editor, using ``-m``.


```bash
$ git commit -m 'Initial commit'
```

If there are no files passed to ``git commit``, then it will commit all staged changes. However, assume that ``foo.txt`` is already being tracked by Git. You can then use ``git commit foo.txt`` to create a new commit with the changes to that file, without the need to stage the file first.

## What is staging?

Staging is a way of organizing which files will be committed. Imagine you are editing several different files, but the changes fall into 3 logical steps. You can stage and then commit just the files you want.

```bash
$ git add foo.txt bar.txt
$ git commit -m 'Updated .txt files for new release'
$ git add myscript.py helper.py
$ git commit -m 'Add feature X'
$ git add CHANGELOG
$ git commit -m 'Updated changelog with new features'
```

It is considered good practice in Git to make your changes "atomic". That is to say, large commits containing a bunch of work are less preferable to separate commits for separate logical steps. Atomic commits make it easier to roll back changes, or apply them to different branches using cherry-picking.

As mentioned above, staging is optional when the files are already being tracked. The above could also have been accomplished using only three commands, if all the files were being tracked by Git:

```bash
$ git commit -m 'Updated .txt files for new release' foo.txt bar.txt
$ git commit -m 'Add feature X' myscript.py helper.py
$ git commit -m 'Updated changelog with new features' CHANGELOG
```

However, files being added to Git for the first time *must be staged first*.

## The DAG

### Overview

The DAG is a way of representing the history of a git repository. The graph moves in a single direction, with each revision pointing back at its parent (or parents).

```
A <--- B <--- C <--- D
```

When a branch is created, the first new commit made in it will share a parent with any changes made to the original branch after that branching point:

```
                 E <--- F <--- G <--- H  otherbranch
                /
               /
A <--- B <--- C <--- D  master
```

Commit ``D`` on the ``master`` branch and commit ``E`` on ``otherbranch`` both have ``C`` as a parent.

### Visualizing the DAG

The ``git log`` command can give you a vertical graph using the following command-line flags:

```bash
$ git log --all --decorate --oneline --graph
```

This can be added as a git alias using the following command:

```bash
$ git config --global alias.graph 'log --all --decorate --oneline --graph'
```

Now you can just run ``git graph`` to get the same result. Another good command for using the ``--graph`` feature of ``git log`` is: ``git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short``.

You can also use a script written by a friend and colleague of mine ([@whiteinge](https://github.com/whiteinge)) called [git-graph-dag](https://raw.githubusercontent.com/foxvalleylug/meetings/master/2017/01/scripts/git-graph-dag). This script requires that ``graphviz`` be installed, and will graph all commits reachable by the specified commit (or range of commits).

Simply place this script somewhere in your PATH, and run the following from your repo:

```bash
$ git-graph-dag HEAD~10.. | dot -Tpng >/tmp/foo.png && qiv /tmp/foo.png
```

NOTE: I'm using ``qiv`` to display the image, replace this with whatever you would like to use to view the image.

## Remote repositories

Git can track remote copies of a repository, to facilitate pushes/pulls and to use as branching points:

```bash
$ git remote add <remote_name> <remote_url>
```

If you've cloned a repository, Git will create a remote named ``origin`` and assign it the URL that you cloned. A common use case for adding another remote would be if you have forked a project on GitHub and you would like to also keep up-to-date with the upstream project you've forked.

## Branching

```bash
# Checkout a new branch from the current commit
$ git checkout -b new-branch

# Checkout a new branch from the head of a local branch
$ git checkout -b new-branch otherbranch
```

Remote branches can also be specified as a branch point, using the ``remotename/branchname`` naming scheme:

```bash
$ git checkout -b new-branch upstream/somebranch
```

Branches can be thought of as pointers to a certain commit. And, as each new commit is made, that pointer moves to the new commit.


## Tagging

Tagging allows you to assign a name to a given revision. Common uses for tags are to denote release points for a project (using, for instance a tag named ``1.2.3`` to denote version 1.2.3).

There are two types of tags, annotated and non-annotated. The difference between the two is that an annotated tag has a message (similar to a commit message) assigned to it (hence calling it an "annotated" tag). It is generally recommended to use an annotated tag, as it allows for more information to be added about why that tag was created.

```bash
# Annotated tag
$ git tag -a v1.2.3

# Non-annotated tag
$ git tag v1.2.3

# List all tags
$ git tag --list
```

While branches and tags both points to revisions, a branch is designed to track an ongoing line of changes (updating its pointer with each commit), while a tag just points to a single revision and does not update.

## Merging

### Overview

Merging changes from one branch into the current branch is done using ``git merge``:

```bash
$ git merge otherbranch
```

This will merge ``otherbranch`` into the current branch. This will create what is called a "merge commit" to mark the merge, with two parent commits. One parent will be from the current branch, and the other will be from the branch being merged.

Now, imagine that we branched from ``master`` to ``otherbranch``, and made a few changes (without changing ``master`` at all), then switched back to ``master``, and ran this command. We would not see a merge commit, but instead the output would start with the following:

```bash
Updating d14f0c64eb..ac8008d843
Fast-forward
```

So, what is a fast-forward? We'll come to that in a moment. First, it will help to understand the [3-way merge](https://en.wikipedia.org/wiki/Merge_%28version_control%29#Recursive_three-way_merge) strategy which Git uses.

### The 3-Way Merge

```
                 D <--- F <--- H  otherbranch
                /
               /
A <--- B <--- C <--- E <--- G  master
```

In this example, ``otherbranch`` was merged at ``C``, and both ``master`` and ``otherbranch`` continued to have changes made to them. The head of the ``master`` branch is now at ``G``, while the head of ``otherbranch`` is at ``H``.

To perform the merge, Git will look back and find a common ancestor between ``G`` and ``H`` (in this case the branching point, ``C``). Then, it will find all of the commits on ``otherbranch`` that come after that ancestor (i.e. ``D``, ``F``, ``H``), and apply them one-by-one on top of ``G``.

The result will be ``I``, with parents ``G`` and ``H``. In this scenario, ``I`` is the merge commit.

```
                 D <--- F <--- H  otherbranch
                /               \
               /                 \
A <--- B <--- C <--- E <--- G <-- I  master
```

### Fast-Forward Merge

So, back to our scenario from above where we branched, and then made changes to the new branch but not the original branch. The DAG would look like this:

```
                 D <--- E <--- F  otherbranch
                /
               /
A <--- B <--- C  master
```

So, when Git goes to find the common ancestor of ``master`` and ``otherbranch``, it will find that the common ancestor ``C`` is the same as the head of the ``master`` branch. In this case, replaying the commits from ``otherbranch`` which come after ``C`` will be exactly the same as if the changes were made on top of ``master``, so Git will just "fast-forward" master to ``F``, resulting in the following:

```
A <--- B <--- C <--- D <--- E <--- F  master / otherbranch
```

At this point, ``master`` and ``otherbranch`` will both point to the same commit, ``F``.

It should be noted that it is possible to force Git to create a merge commit even when the merge is a fast-forward. This is done by adding ``--no-ff`` to the ``git merge`` command:

```bash
$ git merge otherbranch
```

If this were done on the fast-forward example below, the result would look like this:

```
                 D <--- E <--- F  otherbranch
                /               \
               /                 \
A <--- B <--- C <---------------- G  master
```

GitHub actually uses a ``--no-ff`` method under the hood when you merge a pull request.

### Merging Tags and Remote Branches

In Git, merging is not restricted to branches. When Git performs a merge, it's really just working from two revisions. In the examples above, it was merging the head of one branch onto the head of the current branch. But remember, branches are just moving pointers to commits. Git uses the same exact procedure to merge tags and remote branches as it does for any other merge:

1. Find the common ancestor of the current branch and the target being merged
2. Perform changes between common ancestor and merge target on top of current branch

**NOTE:** Git actually exposes the functionality it uses under-the-hood to find the ancestor as a separate Git subcommand called [``git merge-base``](https://git-scm.com/docs/git-merge-base).

## Merge Conflicts

When Git is replaying the changes during a merge, and it finds that the same line was changed in both the current branch and the branch being merged, this is called a merge conflict.

```bash
$ git merge otherbranch
Auto-merging foo.txt
CONFLICT (content): Merge conflict in foo.txt
Automatic merge failed; fix conflicts and then commit the result.
```

When you see this, then you'll need to edit the files with the conflicts and resolve them. The conflict will look like this:

```
<<<<<<< HEAD
Hello world! I feel great!
=======
Hello world! How are you?
>>>>>>> otherbranch
```

The ``=======`` divides the two halves of the conflict, while the ``<<<<<<<`` and ``>>>>>>>`` mark the beginning of the conflicting text on one side of the merge, and the end of the conflicting text on the other side of the merge.

To resolve the conflict, everything between (and including) the angle bracket lines must be removed, leaving only the correct text. Sometimes one half of the conflict (or the other) should be used completely, sometimes the correct solution is a blend of the content on both sides of the conflict. This all depends on the changes that were made on both sides that caused the conflict, so it's dependent on your situation. Once you've resolved all the conflicts, you must stage and then commit.

```bash
$ git add foo.txt
$ git commit
```

When you commit, you will be creating the merge commit.

## Rebasing

### Overview

You've branched from ``master`` to work on some changes, and have accumulated a few commits since branching. In the meantime, changes were made to ``master``:

```
                 D <--- E <--- F  otherbranch
                /
               /
A <--- B <--- C <--- G <--- H  master
```

If you would like to get the benefit of the changes from ``G`` and ``H`` in your working branch (``otherbranch``), or you know that those changes will conflict with yours and you want to resolve the inevitable merge conflict so that ``otherbranch`` will cleanly merge into ``master``, then a rebase is what you need:

```bash
$ git rebase master
```

A rebase will replay the commits made since the common ancestor on top of the rebase target (in this case ``master``), and then point ``otherbranch`` at the result:

```
                               D <--- E <--- F  otherbranch
                              /
                             /
A <--- B <--- C <--- G <--- H  master
```

If, at any point, you get an error/conflict/etc. and you have no idea what you did or know that you did something horribly wrong, you can run ``git rebase --abort``. Git will have remembered where HEAD pointed before you started the rebase and will return you there as if it were all a bad dream. :)

### Interactive Rebasing

Using the ``-i`` (or ``--interactive``) flag when running a rebase will open your editor and show you a summary of the commits that will be replayed. You can then make various changes to the commit, such as:

- Re-wording the commit message
- Combining consecutive commits into a single commit (squash/fixup)
- Reordering commits
  - Timestamps will remain unchanged, reordering just alters the order of the commits in the DAG
- Removing commits altogether

### ``git commit --amend`` - "``git rebase``'s Cousin"

``git commit --amend`` modifies the most recent commit. Let's say that you forgot to include some information in your most recent commit message. Run ``git commit --amend`` and you will be popped into your editor where you can make changes to the commit message. When you save and exit your editor, the commit message will be the new one (and the SHA will have changed).

Another use for amending a commit is if you realize that you forgot something in the code you committed. You can simply make the changes you need, then run ``git commit --amend``:

```bash
# With staging first
$ git add foo.txt
$ git commit --amend

# Without staging
$ git commit --amend foo.txt
```

Both use cases described above could also be accomplished by making a separate commit and then using an interactive rebase to perform a squash or fixup on those two comits, but the fact that we're operating on the most recent commit means that ``git commit --amend`` can be used to do the same task without the need to create a separate commit first.

## Stashing

### Overview

Imagine you've branched and begun working on changes, and there's an unrelated critical bugfix that needs to be made. Git allows you to "stash" changes and apply them later:

```bash
# Stash changes
$ git stash
# Checkout new branch based on the upstream master branch
$ git fetch upstream
$ git checkout -b emergency upstream/master
# Do your changes...
# ...
# ...
# Commit your changes
$ git add . && git commit
# Return to otherbranch
$ git checkout otherbranch
$ git stash apply
```

### Listing Stashes

You can have more than one stash at a time. As you add stashes, they form a stack, with the most-recent stash at the top of the stack. To list stashes run ``git stash list``.

Each stash will be labeled with an ID (e.g. ``stash@{0}``), and will show the working branch at the time of the stash, as well as a message. By default, this message will be the commit message from the most recent commit at the time of the stash. In case this is not descriptive enough, you can use ``git stash save Fix for issue 12345`` and the message will be ``Fix for issue 12345``.

### Applying a Stash from Further Down the Stack

By default ``git stash apply`` will apply ``stash@{0}``. You can apply a different stash by explicitly passing the stash ID:

```bash
$ git stash apply 'stash@{1}'
```

**NOTE:** The quotes are to prevent the curly braces from being interpreted by your shell.

### Deleting stashes

Deleting stashes is accomplished using ``git stash drop``. Just like with applying stashes, ``git stash drop`` assumes ``stash@{0}`` unless explicitly told to drop a different stash (e.g. ``git stash drop stash@{1}``.

## Worktrees

Added in Git 2.5, worktrees are an attempt to solve the use case where one is working on multiple issues at a time and would need to either commit or stash changes to work on a different branch. Using worktrees, you can have different directories which all reference the same git checkout, and each directory can have a different branch checked out.

### My Workflow

When I use worktrees, I like to organize them in the same parent directory as the "main" git checkout. So, I create a directory and then clone (or init) my repository into a subdirectory called "main":

```bash
$ mkdir -p ~/git/projectname
$ git clone <REPO_URL> main
```

### Adding

The simplest way of adding a worktree is to be in the root of your main checkout (or another worktree) and run:

```bash
$ git worktree add ../issue123
```

This will do the following:

1. Create a new worktree at that path
2. Create a new branch based on the basename of the worktree directory (i.e. ``issue123``) and checkout that branch at whatever HEAD was pointing to

To work in this new worktree, simply cd into it.

The [manpage](https://git-scm.com/docs/git-worktree) has examples of other options that can be passed at the time the worktree is created, to do things such as giving the branch a different name, using a different revision for the branch point, etc.

### Listing

To list worktrees, simply run ``git worktree list``. Adding ``--porcelain`` to this command will output the worktrees in a parsable format, useful for scripting.

**NOTE:** This command will work even if you haven't created any worktrees. It will show your main checkout as a worktree regardless of whether or not you've created any others.

### Removing

Removing a worktree is a 2-step process. First you must remove the worktree directory (using ``rm -rf`` or whatever the Windows equivalent is) and then from a different worktree run ``git worktree prune``. Running this command alone will produce no output (unless there are errors), so I find it useful to add ``-v`` for verbose output:

```bash
$ git worktree prune -v
```

**NOTE:** Pruning the worktree will not remove the branch that was checked out. This must be done separately using ``git branch -d branch_name`` (or ``git branch -D branch_name``).

## Recommended Reading

- [Official Documentation](https://git-scm.com/doc)
- [**Pro Git** E-book](https://git-scm.com/book/en/v2)
  - Browsable online
  - Downloads available in PDF, EPUB, MOBI (used by Kindle devices), and HTML
  - Dead tree version also available on Amazon.com
- [Git Ready](http://gitready.com/)
  - Excellent tutorial with beginner, intermediate, and advanced topics
- [GitHub Blog](https://github.com/blog)
  - Contains mostly GitHub-specific information, but occasionally will have good articles on how to do certain tasks in Git
  - Writeups are posted for new Git releases with helpful explanations of what is new, making this blog a good resource for keeping up with changes to Git
- [GitHub Guides](https://guides.github.com/)
  - Again, mostly useful information for interacting with GitHub, but still quite a bit of good knowledge here
