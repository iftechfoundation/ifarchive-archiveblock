# Apache plugin for restricting files

This tool is part of a system for restricting certain [IF Archive][ifarch] files from being served in the UK. It sucks that we have to do this, but we do. See discussion of the [UK Online Safety Act][ukosa].

[ifarch]: https://ifarchive.org/
[ukosa]: https://intfiction.org/t/uk-online-safety-act/75867

This plugin does not handle the geolocation check itself. The entire process looks like this:

- The `Index` files on the [Archive][ifarch] contain file tags like `safety: self-harm`.
- The [ifmap][] script reads these and constructs a text file which maps filenames to tag lists.
- This Apache plugin loads the map file. When a request comes in for a tagged file, the browser is redirected to the `ukrestrict.ifarchive.org` domain.
- Cloudflare (the front-end for the public Archive service) does a geolocation check for any request that hits the `ukrestrict.ifarchive.org` domain. If the request comes from the UK, it is redirected to [https://ifarchive.org/misc/uk-block.html](https://ifarchive.org/misc/uk-block.html).

[ifmap]: https://github.com/iftechfoundation/ifarchive-ifmap-py

Why an Apache plugin? The redirect step is a bit too messy to handle with standard Apache tools like `[mod_alias][]` or `[mod_rewrite][]`. The tricky requirements:

[mod_alias]: https://httpd.apache.org/docs/current/mod/mod_alias.html
[mod_rewrite]: https://httpd.apache.org/docs/current/mod/mod_rewrite.html

- The map file may be updated at any time. We must watch it and reload if the file timestamp changes.
- We must be able to tag entire directories, since the tagging process is being worked on incrementally. (Many directories have not even been looked at yet.)
- All tagged files must get a `X-IFArchive-Safety` HTTP header.
- Redirects must have the `Access-Control-Allow-Origin: *` header, so that client-side services like `[iplayif.com][]` can detect them.

[iplayif.com]: https://iplayif.com/

Happily, the [Apache C API][modapi] for modules is powerful enough to do what we need.

[modapi]: https://httpd.apache.org/docs/2.4/developer/modguide.html

## Building the plugin

You will need the `[apxs][]` tool. If you're on Linux, you may need to install the `apache2-dev` package.

[apxs]: https://httpd.apache.org/docs/2.4/programs/apxs.html

To build and install the plugin:

```
sudo apxs -i -c mod_archiveblock.c
```

Note that the `Makefile` in this repository is set up for the Archive's Linux environment. You will need a different config for MacOS, etc. Type `apxs -n archiveblock -g` in an empty directory to create a buildable plugin template.

