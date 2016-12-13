## Instructions for Contributing to the StorageOS documentation

These instructions work on Mac, Windows and Linux.

All steps are run from a terminal console.

You will need the following software installed:
- docker (https://www.docker.com/products/overview)
- git (https://git-scm.com/downloads)
- text editor (https://atom.io recommended, with following packages: language-markdown, markdown-preview-plus)
- Dapper (http://github.com/rancher/dapper)


## Staging the site locally (from scratch setup)

Make sure Docker is running (download and install from https://www.docker.com/products/overview).

The below commands to setup your environment for running GitHub pages locally. Then, any edits you make will be viewable
on a lightweight webserver that runs on your local machine.

This will typically be the fastest way (by far) to iterate on docs changes and see them staged.

Clone this repository:

```
git clone ssh://git@code.storageos.net:7999/pub/docs.git
```

Run a local copy:

```
make serve
```

Your copy of the site will then be viewable at: [http://localhost:4000](http://localhost:4000)
(or wherever Jekyll tells you).

You may edit the files while the server is running, and pages will update whenever they are saved.

## Documenter's Workflow

1. Create a Jira ticket or start work on an existing ticket.
2. In the ticket view, Select "Create branch" in the bottom-right corner.
3. Go to a command-line prompt where you have the documentation checked out.
4. Checkout `master` branch: `git checkout master`
5. Run `git pull`.  You will see the new branch appear.
6. Switch to the new branch: `git checkout feature/DEV-999-update-docs` (use new branch name here)
7. Make changes, and test locally.
8. Commit changes frequently: `git commit -a`.  Use a commit message to describe what you changed.
9. Push your changes when ready: `git push`.  This will copy your changes to the central server.  You will not break existing work, so don't worry!
10. Create a pull request.  The easiest way is to follow the steps suggested by the previous command, otherwise you can go to:
[http://code.storageos.net/projects/PUB/repos/docs/pull-requests?create]()
11. Post to the `awesome-dev-dudes` channel on Slack to let us know you're waiting for review.

## Publish to docs.storageos.com (password-protected)

The password-protected documentation site currently runs on the downloads server (Ubuntu running on DigitalOcean).  This site is used by closed-beta users.

The site will be automatically published whenever pull requests are merged into the master branch.  The Jenkins job that controls this is [http://ci.storageos.net/job/public-docs/]()


## Publish to GitHub Pages (not password-protected)

:warning: This is not currently in use, as we do not wish to publish documentation until we have patents in place.