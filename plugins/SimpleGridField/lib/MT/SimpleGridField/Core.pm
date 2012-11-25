package MT::SimpleGridField::Core;

use strict;

use JSON;
use MT::SimpleGridField::Util;

sub init_app {
    my ( $cb, $app ) = @_;

    MT::SimpleGridField::Util::install_grid_tags($app);
}

sub field_html_params {
    my ( $key, $tmpl_key, $tmpl_param ) = @_;

    # Default JSON
    $tmpl_param->{value} ||= '{"rows":[]}';

    my $app = MT->instance->isa('MT::App') ? MT->instance : return;
    my $author = $app->user || return;
    my $perms = $app->permissions || return;
    my $blog = $app->blog;

    if ( ( $blog && $perms->can_administer_blog ) || ( !$blog && $author->is_superuser ) ) {
        $tmpl_param->{source_viewable} = 1;
    }
}

1;