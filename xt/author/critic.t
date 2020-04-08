use Test2::Require::Module 'Test2::Tools::PerlCritic';
use Test2::Require::Module 'Perl::Critic';
use Test2::Require::Module 'Perl::Critic::Freenode';
use Test2::V0;
use Perl::Critic;
use Test2::Tools::PerlCritic;

my $critic = Perl::Critic->new(
  -profile => 'perlcriticrc',
);

perl_critic_ok ['examples','lib','t'], $critic;

done_testing;


