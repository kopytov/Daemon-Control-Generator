# NAME

dc-gen - generates init files for Daemon::Control

# VERSION

version 0.001

# SYNOPSIS

Print generated script:

    dc-gen --program=/opt/postgres/9.4/bin/postgres

More complex:

    dc-gen --program=/opt/postgres/9.4/bin/postgres            \
       --user=postgres --init_code='export LANG="ru_RU.UTF-8"' \
       -- -D /var/opt/posgres/9.4/data

Generate and save script to /etc/opt/dc-gen:

    dc-gen --program=/opt/postgres/9.4/bin/postgres --save

Add it to system init (CentOS 6):

    /etc/opt/dc-gen/postgres get_init_file >/etc/init.d/postgres
    chkconfig --add postgres
    chkconfig postgres on

# INSTALL

    cpanm Daemon::Control::Generator -M http://cpan.linuxprofy.net/public

# SEE ALSO

[Daemon::Control](https://metacpan.org/pod/Daemon::Control)

# AUTHOR

Dmitry Kopytov <kopytov@webhackers.ru>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dmitry Kopytov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
