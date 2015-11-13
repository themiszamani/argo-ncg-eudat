#!/usr/bin/perl

$SERVICE_TEMPL->{2}->{path} = '/usr/libexec/grid-monitoring/probes';
$SERVICE_TEMPL->{2}->{interval} = 5;
$SERVICE_TEMPL->{2}->{timeout} = 60;
$SERVICE_TEMPL->{2}->{retryInterval} = 2;
$SERVICE_TEMPL->{2}->{maxCheckAttempts} = 2;
$SERVICE_TEMPL->{5}->{path} = '/usr/libexec/grid-monitoring/probes';
$SERVICE_TEMPL->{5}->{interval} = 5;
$SERVICE_TEMPL->{5}->{timeout} = 30;
$SERVICE_TEMPL->{5}->{retryInterval} = 3;
$SERVICE_TEMPL->{5}->{maxCheckAttempts} = 3;
$SERVICE_TEMPL->{15}->{path} = '/usr/libexec/grid-monitoring/probes';
$SERVICE_TEMPL->{15}->{interval} = 15;
$SERVICE_TEMPL->{15}->{timeout} = 120;
$SERVICE_TEMPL->{15}->{retryInterval} = 5;
$SERVICE_TEMPL->{15}->{maxCheckAttempts} = 4;
$SERVICE_TEMPL->{30}->{path} = '/usr/libexec/grid-monitoring/probes';
$SERVICE_TEMPL->{30}->{interval} = 30;
$SERVICE_TEMPL->{30}->{timeout} = 30;
$SERVICE_TEMPL->{30}->{retryInterval} = 5;
$SERVICE_TEMPL->{30}->{maxCheckAttempts} = 3;
$SERVICE_TEMPL->{60}->{path} = '/usr/libexec/grid-monitoring/probes';
$SERVICE_TEMPL->{60}->{interval} = 60;
$SERVICE_TEMPL->{60}->{timeout} = 600;
$SERVICE_TEMPL->{60}->{retryInterval} = 15;
$SERVICE_TEMPL->{60}->{maxCheckAttempts} = 4;
$SERVICE_TEMPL->{360}->{path} = '/usr/libexec/grid-monitoring/probes';
$SERVICE_TEMPL->{360}->{interval} = 360;
$SERVICE_TEMPL->{360}->{timeout} = 30;
$SERVICE_TEMPL->{360}->{retryInterval} = 15;
$SERVICE_TEMPL->{360}->{maxCheckAttempts} = 3;
$SERVICE_TEMPL->{1440}->{path} = '/usr/libexec/grid-monitoring/probes';
$SERVICE_TEMPL->{1440}->{interval} = 1440;
$SERVICE_TEMPL->{1440}->{timeout} = 120;
$SERVICE_TEMPL->{1440}->{retryInterval} = 60;
$SERVICE_TEMPL->{1440}->{maxCheckAttempts} = 4;
$SERVICE_TEMPL->{240}->{path} = '/usr/libexec/grid-monitoring/probes';
$SERVICE_TEMPL->{240}->{interval} = 240;
$SERVICE_TEMPL->{240}->{timeout} = 60;
$SERVICE_TEMPL->{240}->{retryInterval} = 30;
$SERVICE_TEMPL->{240}->{maxCheckAttempts} = 4;
$SERVICE_TEMPL->{native_5}->{path} = '$USER1$';
$SERVICE_TEMPL->{native_5}->{interval} = 5;
$SERVICE_TEMPL->{native_5}->{timeout} = 30;
$SERVICE_TEMPL->{native_5}->{retryInterval} = 3;
$SERVICE_TEMPL->{native_5}->{maxCheckAttempts} = 3;
$SERVICE_TEMPL->{native_15}->{path} = '$USER1$';
$SERVICE_TEMPL->{native_15}->{interval} = 15;
$SERVICE_TEMPL->{native_15}->{timeout} = 60;
$SERVICE_TEMPL->{native_15}->{retryInterval} = 5;
$SERVICE_TEMPL->{native_15}->{maxCheckAttempts} = 4;

require NCG::LocalMetrics::Hash_local;
use JSON;
if ($NCG::LocalMetrics::Hash_local::WLCG_SERVICE) {
    print to_json($NCG::LocalMetrics::Hash_local::WLCG_SERVICE,
              { ascii => 1, pretty => 1 });
} elsif ($WLCG_SERVICE) {
    print to_json($WLCG_SERVICE,
              { ascii => 1, pretty => 1 });
} else {
    print "Cannot load variable WLCG_SERVICE\n";
}
