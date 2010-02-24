use inc::Module::Install;

name     'File-Abstract';
all_from 'lib/File/Abstract.pm';
author   q{Blabos de Blebe <blabos@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

