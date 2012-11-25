package MT::SimpleGridField::Util;

use strict;
use base 'Exporter';
our @EXPORT = qw(plugin install_grid_tags);

use JSON;

sub plugin { MT->component('SimpleGridField') }

sub _hdlr_customfield_grid_by_tag {
    my ($ctx) = @_;

    # Asset tags end in "asset."
    my $tag = $ctx->stash('tag');
    $tag =~ s{ rows \z }{}xmsi;

    my $field = $ctx->stash('field')
        or return _no_field($ctx);
    local $ctx->{__stash}{field} = $field;

    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $res     = '';

    require CustomFields::Template::ContextHandlers;
    my $value = CustomFields::Template::ContextHandlers::_hdlr_customfield_value(@_);

    return '' unless $value;

    my $json = eval { from_json($value) } || return '';
    my $rows = $json->{rows} || return '';
    $rows = eval { from_json($rows) } unless ref $rows;
    return '' if ref $rows ne 'ARRAY';

    require MT::Template::Handler;
    for my $row ( @$rows ) {
        next if ref $row ne 'HASH';

        # Assign vars
        my @vars = sort { $a cmp $b } keys %$row;
        my @values = map { $row->{$_} } @vars;
        my $stash_vars = $ctx->{__stash}{vars};
        local @$stash_vars{@vars} = @values;

        # SNIPET: Dynamic column handlers
        # my @tags = map { 'row' . $_ } @vars;
        # my @handlers = map {
        #     my $value = $row->{$_};
        #     MT::Template::Handler->new( sub {
        #         $value;
        #     }, 0);
        # } @vars;
        # my $stash_handlers = $ctx->{__handlers};
        # local @$stash_handlers{@tags} = @handlers;

        defined( my $out = $builder->build( $ctx, $tokens ) )
            or return $ctx->error( $builder->errstr );
        $res .= $out;
    }

    $res;
}

sub install_grid_tags {
    my $app = shift;

    # Append *Rows tags for gird types
    my $cmpnt = MT->component('commercial');
    my $tags  = $cmpnt->registry('tags');
    my $fields = $cmpnt->{customfields} || return 1;

    my $handler_grid = \&_hdlr_customfield_grid_by_tag;

    FIELD: for my $field (@$fields) {
        next if $field->type ne 'text_and_textarea_grid';

        my $tag = $field->tag
            or next FIELD;
        $tag = lc($tag) . 'rows';

        # We may be redefining these tags, but they're just string
        # references anyway.
        $tags->{block}->{$tag} = sub {
            local $_[0]->{__stash}{tag}   = $tag;
            local $_[0]->{__stash}{field} = $field;
            $handler_grid->(@_);
        };
    }

    return 1;
}

1;
__END__ 