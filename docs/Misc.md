# Miscellaneous Documentation

## Git Subtrees

We use subtrees for PrefixedJSONKit and PrefixedTTTAttributedLabel. To update one of them, use one of:

`git subtree pull --prefix ApptentiveConnect/ext/PrefixedTTTAttributedLabel git@github.com:apptentive/PrefixedTTTAttributedLabel.git master --squash`

or

`git subtree pull --prefix ApptentiveConnect/ext/PrefixedJSONKit git@github.com:apptentive/PrefixedJSONKit.git master --squash`

There's more information available on `git subtree` on this [Atlassian blog post](http://blogs.atlassian.com/2013/05/alternatives-to-git-submodule-git-subtree/).