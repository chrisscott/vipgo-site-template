# VIP Go VVV Site Template

This site template is used to set up a local VIP Go dev environment using VVV. It automates the steps in the [VIP documentation](https://vip.wordpress.com/documentation/vip-go/local-vip-go-development-environment/) for local development on VIP Go.

**IMPORTANT**: This is only for VIP Go and will not work for WordPress.com VIP sites.

# Using This Template With VVV

**NOTE**: All configuration happens in VVV's `vvv-custom.yml` file. You do not need to clone, download, or otherwise do anything with this repo.

1. [Install VVV](https://varyingvagrantvagrants.org/docs/en-US/installation/)
2. After copying `vvv-config.yml` to `vvv-custom.yml` make the following updates to `vvv-custom.yml`: 

    In the `sites` section, add a site using this repository, and specifying your VIP Go site repo, e.g.:
    ```yaml
    vipsite:
      repo: git@github.com:chrisscott/vip-go-vvv-site-template.git
      hosts:
        - vipsite.test
      custom:
        vip-repo: git@github.com:wpcomvip/[your site repo].git
    ```

    * `repo` will use this repo to configure your site.
    * `vip-repo` is the GitHub git URL to the repo provided by VIP for the site you are configuring.
    * The site will live in `www/vipsite`

    For example, here's what a full `sites` section would might like if the git repo was named `vipsite` and you want to use that as the hostname as well:

    ```yaml
    sites:
      vipsite:
        repo: git@github.com:chrisscott/vip-go-vvv-site-template.git
        hosts:
          - vipsite.test
        custom:
          vip-repo: git@github.com:wpcomvip/vipsite.git
    ```
3. Run `vagrant up --provision`. Keep an eye out for any console messages prepended with `VIP:`. 

## IMPORTANT

* If this is your first provision after installing VVV, reboot your computer to make sure networking changes take effect.
* Due to username restrictions on VIP Go, the default WordPress credentials are not used. Instead, the following WordPress credentials must be used after provisioning:
  * Username: `wp`
  * Password: `wp`
* Running `vagrant up --provision` is required after any change to `vvv-custom.yml`. This is non-destructive and will also update the VIP Go mu-plugins.
