# gerrit review comments package for Atom
View comments from a Gerrit review directly inside the Atom Editor.

![](https://github.com/mhuin/atom-gerrit-comments/raw/master/screenshot.png)

This package is a fork of **[atom-pull-requests](https://github.com/philschatz/atom-pull-requests)**.

# Config

The package uses the Gerrit REST API to fetch data. The Gerrit service must
therefore provide this endpoint, and means of authentication.

You need to define a configuration file so that the package knows where to fetch
comments, and how to authenticate. The format is the following:

```yaml
servers:
  - name: openstack
    remote: review.openstack.org
    url: https://review.openstack.org/r/
    user: mhu
    password: InY00rDr34mz
```

You can define as many servers as you wish, if you are working with several Gerrit
instances.

The **remote** field is a regular expression that will be applied to your working
repository's "gerrit" branch.

# Disclaimer

I am very new at CoffeeScript and Atom packages, expect clumsy code and so on.
Contributions more than welcome !
