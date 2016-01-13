%define lperllib modules/NCG
%define templatedir %{_datadir}/grid-monitoring/config-gen/nagios
%define configdir /etc/ncg
%define perllib %{perl_vendorarch}/vendor_perl/5.8.5

Summary: WLCG monitoring configuration generator
Name: argo-ncg-eudat
Version: 0.96.2
Release: 2%{?dist}
License: ASL 2.0
Group: Network/Monitoring
Source0: %{name}-%{version}.tar.gz
Obsoletes: grid-monitoring-config-gen
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: x86_64
Provides: perl(NCG::LocalMetrics::Hash_local)

%description
(NULL)

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT

#
# Docs
#
install --directory $RPM_BUILD_ROOT%{_datadir}/doc/%{name}-%{version}
install   CHANGES $RPM_BUILD_ROOT%{_datadir}/doc/%{name}-%{version}
install   README $RPM_BUILD_ROOT%{_datadir}/doc/%{name}-%{version}
install   INSTALL $RPM_BUILD_ROOT%{_datadir}/doc/%{name}-%{version}
#
# App
#
install --directory $RPM_BUILD_ROOT%{_sbindir}
install --directory $RPM_BUILD_ROOT/usr/libexec
install --mode=755 ncg.pl $RPM_BUILD_ROOT%{_sbindir}
install --mode=755 ncg.reload.sh $RPM_BUILD_ROOT%{_sbindir}
install --mode=755 hashlocal-to-json.pl $RPM_BUILD_ROOT/usr/libexec
#
# Config
#
install --directory $RPM_BUILD_ROOT%{configdir}/ncg.conf.d/
install --directory $RPM_BUILD_ROOT%{configdir}/
install config/ncg.conf $RPM_BUILD_ROOT%{configdir}
install config/ncg.conf.example $RPM_BUILD_ROOT%{configdir}
install config/ncg.localdb $RPM_BUILD_ROOT%{configdir}
install config/ncg.localdb.example $RPM_BUILD_ROOT%{configdir}
install config/ncg.multisite.conf $RPM_BUILD_ROOT%{configdir}
install config/ncg.atpvo.conf $RPM_BUILD_ROOT%{configdir}
install config/check_logfiles_ncg.conf $RPM_BUILD_ROOT%{configdir}
install --directory $RPM_BUILD_ROOT/etc/nagios/nrpe
install --directory $RPM_BUILD_ROOT/etc/nagios/wlcg.d
install --directory $RPM_BUILD_ROOT/etc/nagios/unicore
install --mode=644 config/unicore/log4j-ucc.properties $RPM_BUILD_ROOT/etc/nagios/unicore
install --mode=644 config/unicore/log4j-ucc-debug.properties $RPM_BUILD_ROOT/etc/nagios/unicore
install --mode=644 config/unicore/log4j-uvosclc.properties $RPM_BUILD_ROOT/etc/nagios/unicore
install --mode=644 config/unicore/log4j-uvosclc-debug.properties $RPM_BUILD_ROOT/etc/nagios/unicore
install --mode=644 config/unicore/UNICORE_Job.u $RPM_BUILD_ROOT/etc/nagios/unicore
#
# modules
#
install --directory $RPM_BUILD_ROOT%{perllib}/NCG/ConfigGen
install --directory $RPM_BUILD_ROOT%{perllib}/NCG/ConfigPublish
install --directory $RPM_BUILD_ROOT%{perllib}/NCG/LocalMetricsAttrs
install --directory $RPM_BUILD_ROOT%{perllib}/NCG/SiteInfo
install --directory $RPM_BUILD_ROOT%{perllib}/NCG/SiteContacts
install --directory $RPM_BUILD_ROOT%{perllib}/NCG/SiteSet
install --directory $RPM_BUILD_ROOT%{perllib}/NCG/LocalMetrics
install --directory $RPM_BUILD_ROOT%{perllib}/NCG/RemoteMetrics
install --mode=644 modules/NCG/ConfigGen/Nagios.pm $RPM_BUILD_ROOT%{perllib}/NCG/ConfigGen
install --mode=644 modules/NCG/ConfigPublish/ConfigCache.pm $RPM_BUILD_ROOT%{perllib}/NCG/ConfigPublish
install --mode=644 modules/NCG/LocalMetricsAttrs/Active.pm $RPM_BUILD_ROOT%{perllib}/NCG/LocalMetricsAttrs
install --mode=644 modules/NCG/LocalMetricsAttrs/File.pm $RPM_BUILD_ROOT%{perllib}/NCG/LocalMetricsAttrs
install --mode=644 modules/NCG/LocalMetricsAttrs/LDAP.pm $RPM_BUILD_ROOT%{perllib}/NCG/LocalMetricsAttrs
install --mode=644 modules/NCG/SiteInfo/ATP.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteInfo
install --mode=644 modules/NCG/SiteInfo/GOCDB.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteInfo
install --mode=644 modules/NCG/SiteInfo/File.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteInfo
install --mode=644 modules/NCG/SiteInfo/LDAP.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteInfo
install --mode=644 modules/NCG/SiteSet/ATP.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteSet
install --mode=644 modules/NCG/SiteSet/GOCDB.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteSet
install --mode=644 modules/NCG/SiteSet/File.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteSet
install --mode=644 modules/NCG/SiteSet/LDAP.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteSet
install --mode=644 modules/NCG/SiteContacts/ATP.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteContacts
install --mode=644 modules/NCG/SiteContacts/GOCDB.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteContacts
install --mode=644 modules/NCG/SiteContacts/LDAP.pm $RPM_BUILD_ROOT%{perllib}/NCG/SiteContacts
install --mode=644 modules/NCG/SiteContacts/File.pm  $RPM_BUILD_ROOT%{perllib}/NCG/SiteContacts
install --mode=644 modules/NCG/LocalMetrics/File.pm $RPM_BUILD_ROOT%{perllib}/NCG/LocalMetrics
install --mode=644 modules/NCG/LocalMetrics/Hash.pm $RPM_BUILD_ROOT%{perllib}/NCG/LocalMetrics
install --mode=644 modules/NCG/LocalMetrics/POEM.pm $RPM_BUILD_ROOT%{perllib}/NCG/LocalMetrics
install --mode=644 modules/NCG/RemoteMetrics/Nagios.pm $RPM_BUILD_ROOT%{perllib}/NCG/RemoteMetrics
install --mode=644 modules/NCG/LocalMetrics.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/SiteInfo.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/SiteSet.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/SiteContacts.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/ConfigGen.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/ConfigPublish.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/MetricConfig.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/ConfigConverter.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/LocalMetricsAttrs.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/RemoteMetrics.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG/SiteDB.pm $RPM_BUILD_ROOT%{perllib}/NCG
install --mode=644 modules/NCG.pm $RPM_BUILD_ROOT%{perllib}
#
# templates
#
install --directory $RPM_BUILD_ROOT%{templatedir}/wlcg.nrpe
install --directory $RPM_BUILD_ROOT%{templatedir}/hosts
install --directory $RPM_BUILD_ROOT%{templatedir}/services
install --directory $RPM_BUILD_ROOT%{templatedir}/wlcg.nagios
install --directory $RPM_BUILD_ROOT%{templatedir}/contacts
install config/templates/wlcg.nrpe/native.commands.template $RPM_BUILD_ROOT%{templatedir}/wlcg.nrpe
install config/templates/hosts/hostgroup.template  $RPM_BUILD_ROOT%{templatedir}/hosts
install config/templates/hosts/host.template  $RPM_BUILD_ROOT%{templatedir}/hosts
install config/templates/services/nagios.template  $RPM_BUILD_ROOT%{templatedir}/services
install config/templates/services/native.template  $RPM_BUILD_ROOT%{templatedir}/services
install config/templates/services/wlcg.passive.template  $RPM_BUILD_ROOT%{templatedir}/services
install config/templates/services/servicegroup.template  $RPM_BUILD_ROOT%{templatedir}/services
install config/templates/services/servicedependency.template  $RPM_BUILD_ROOT%{templatedir}/services
install config/templates/services/wlcg.nrpe.template  $RPM_BUILD_ROOT%{templatedir}/services
install config/templates/wlcg.nagios/nrpe.template  $RPM_BUILD_ROOT%{templatedir}/wlcg.nagios
install config/templates/contacts/contactgroup.template  $RPM_BUILD_ROOT%{templatedir}/contacts
install config/templates/contacts/contact.template  $RPM_BUILD_ROOT%{templatedir}/contacts
install config/templates/contacts.template  $RPM_BUILD_ROOT%{templatedir}
install config/templates/hosts.template  $RPM_BUILD_ROOT%{templatedir}
install config/templates/commands.template  $RPM_BUILD_ROOT%{templatedir}
install config/templates/services.template  $RPM_BUILD_ROOT%{templatedir}
#
# config dirqueue
install --directory $RPM_BUILD_ROOT/var/run/ncg
#
# misc
#
install --directory $RPM_BUILD_ROOT%{_sysconfdir}/profile.d
install etc/perllib.sh $RPM_BUILD_ROOT%{_sysconfdir}/profile.d/perllib.sh
install etc/perllib.csh $RPM_BUILD_ROOT%{_sysconfdir}/profile.d/perllib.csh
install --directory $RPM_BUILD_ROOT%{_sysconfdir}/ncg-metric-config.d
install ncg-metric-config.d/ncg-metric-config.conf $RPM_BUILD_ROOT%{_sysconfdir}/ncg-metric-config.conf
install ncg-metric-config.d/cloudmon.conf $RPM_BUILD_ROOT%{_sysconfdir}/ncg-metric-config.d/cloudmon.conf
install ncg-metric-config.d/opsmon.conf $RPM_BUILD_ROOT%{_sysconfdir}/ncg-metric-config.d/opsmon.conf

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%config(noreplace) %{configdir}/ncg.conf.d
%config(noreplace) %{configdir}/ncg.conf
%config(noreplace) %{configdir}/ncg.localdb
%config(noreplace) %{configdir}/ncg.conf.example
%config(noreplace) %{configdir}/ncg.localdb.example
%config(noreplace) %{configdir}/ncg.multisite.conf
%config(noreplace) %{configdir}/ncg.atpvo.conf
%config(noreplace) /etc/nagios/nrpe
%config(noreplace) /etc/nagios/wlcg.d
%config(noreplace) /etc/nagios/unicore/log4j-ucc.properties
%config(noreplace) /etc/nagios/unicore/log4j-ucc-debug.properties
%config(noreplace) /etc/nagios/unicore/log4j-uvosclc.properties
%config(noreplace) /etc/nagios/unicore/log4j-uvosclc-debug.properties
/etc/nagios/unicore/UNICORE_Job.u
%{configdir}/check_logfiles_ncg.conf
%doc %{_datadir}/doc/%{name}-%{version}/CHANGES
%doc %{_datadir}/doc/%{name}-%{version}/INSTALL
%doc %{_datadir}/doc/%{name}-%{version}/README
%{_sbindir}/ncg.pl
%{_sbindir}/ncg.reload.sh
/usr/libexec/hashlocal-to-json.pl
%{perllib}/NCG.pm
%{perllib}/NCG/ConfigConverter.pm
%{perllib}/NCG/ConfigGen.pm
%{perllib}/NCG/ConfigGen/Nagios.pm
%{perllib}/NCG/ConfigPublish.pm
%{perllib}/NCG/ConfigPublish/ConfigCache.pm
%{perllib}/NCG/LocalMetrics.pm
%{perllib}/NCG/LocalMetrics/File.pm
%{perllib}/NCG/LocalMetrics/POEM.pm
%{perllib}/NCG/LocalMetrics/Hash.pm
%{perllib}/NCG/LocalMetricsAttrs.pm
%{perllib}/NCG/LocalMetricsAttrs/Active.pm
%{perllib}/NCG/LocalMetricsAttrs/File.pm
%{perllib}/NCG/LocalMetricsAttrs/LDAP.pm
%{perllib}/NCG/MetricConfig.pm
%{perllib}/NCG/RemoteMetrics.pm
%{perllib}/NCG/RemoteMetrics/Nagios.pm
%{perllib}/NCG/SiteContacts.pm
%{perllib}/NCG/SiteContacts/ATP.pm
%{perllib}/NCG/SiteContacts/GOCDB.pm
%{perllib}/NCG/SiteContacts/LDAP.pm
%{perllib}/NCG/SiteContacts/File.pm
%{perllib}/NCG/SiteInfo.pm
%{perllib}/NCG/SiteInfo/ATP.pm
%{perllib}/NCG/SiteInfo/GOCDB.pm
%{perllib}/NCG/SiteInfo/File.pm
%{perllib}/NCG/SiteInfo/LDAP.pm
%{perllib}/NCG/SiteSet.pm
%{perllib}/NCG/SiteSet/ATP.pm
%{perllib}/NCG/SiteSet/GOCDB.pm
%{perllib}/NCG/SiteSet/File.pm
%{perllib}/NCG/SiteSet/LDAP.pm
%{perllib}/NCG/SiteDB.pm
%{templatedir}/wlcg.nrpe/native.commands.template
%{templatedir}/hosts/hostgroup.template
%{templatedir}/hosts/host.template
%{templatedir}/services/nagios.template
%{templatedir}/services/native.template
%{templatedir}/services/wlcg.passive.template
%{templatedir}/services/servicegroup.template
%{templatedir}/services/servicedependency.template
%{templatedir}/services/wlcg.nrpe.template
%{templatedir}/wlcg.nagios/nrpe.template
%{templatedir}/contacts/contactgroup.template
%{templatedir}/contacts/contact.template
%{templatedir}/contacts.template
%{templatedir}/hosts.template
%{templatedir}/commands.template
%{templatedir}/services.template
%dir %attr(0770,nagios,nagios) /var/run/ncg
%{_sysconfdir}/profile.d/perllib.sh
%{_sysconfdir}/profile.d/perllib.csh
%{_sysconfdir}/ncg-metric-config.conf
%{_sysconfdir}/ncg-metric-config.d/cloudmon.conf
%{_sysconfdir}/ncg-metric-config.d/opsmon.conf

%pre
if [ -f /etc/init.d/ncg ] ; then
   /sbin/service ncg stop || echo "ncg service was already stopped"
   /sbin/chkconfig --del ncg
fi

%changelog
* Mon Nov 17 2014 Emir Imamagic <eimamagi@srce.hr> - 0.95.0-1
- Add Nagios hostgroups for NGI/ROC
  https://github.com/ARGOeu/sam-probes/issues/23
- Extract BDII/ARC-sysinfo port from GOCDB
  https://github.com/ARGOeu/sam-probes/issues/3

* Wed Apr 23 2014 Marian Babik <marian.babik@cern.ch> - 0.94.2-1
- WLCGPROB-51 Fix SAM analyze function (added Condor-JobState)

* Wed Nov 27 2013 Emir Imamagic <eimamagi@srce.hr> - 0.94.1-1
- SAM-3285 Issue with multi VO Sam Nagios
- SAM-3028 Multi-FQAN support in Nagios

* Mon May 13 2013 Emir Imamagic <eimamagi@srce.hr> - 0.93.6-1
- SAM-3105 Integrate ARC probes

* Thu May 2 2013 Emir Imamagic <eimamagi@srce.hr> - 0.93.5-1
- SAM-3261 NCG should die gracefully when internal metric is not 
  defined in ncg-metric-config

* Wed May 1 2013 Emir Imamagic <eimamagi@srce.hr> - 0.93.4-1
- SAM-3223 Integrate new MPI probes

* Tue Apr 2 2013 Emir Imamagic <eimamagi@srce.hr> - 0.93.3-1
- SAM-3203 Enable definition of passive metrics without parent

* Wed Mar 27 2013 Emir Imamagic <eimamagi@srce.hr> - 0.93.1-1
- SAM-3233 Mapping of org.sam.CE-JobSubmit

* Fri Feb 22 2013 Emir Imamagic <eimamagi@srce.hr> - 0.92.3-1
- SAM-3115 Integrate GLEXEC probe

* Thu Dec 6 2012 Emir Imamagic <eimamagi@srce.hr> - 0.92.2-1
- SAM-3109 Integrate new JobMonit metrics

* Thu Dec 6 2012 Emir Imamagic <eimamagi@srce.hr> - 0.91.3-1
- SAM-2065 Enable defining contacts for services
- SAM-2655 Proxies generated by hr.srce.GridProxy-Get should be longer

* Thu Nov 29 2012 Emir Imamagic <eimamagi@srce.hr> - 0.91.1-1
- SAM-3029 Join ncg-metric-config and ncg.localdb

* Wed Nov 7 2012 Emir Imamagic <eimamagi@srce.hr> - 0.90.16-1
- SAM-3036 Change CEs to CREAM-CEs for hr.srce.GoodCEs-ops

* Fri Oct 19 2012 Emir Imamagic <eimamagi@srce.hr> - 0.90.15-1
- SAM-3015 Mail notifications not sent to NCG_NAGIOS_ADMIN

* Thu Sep 20 2012 Emir Imamagic <eimamagi@srce.hr> - 0.90.14-1
- SAM-2971 Clean ops-monitor config for message brokers

* Fri Aug 31 2012 Emir Imamagic <eimamagi@srce.hr> - 0.90.13-1
- SAM-2942 NCG should only report WARNING if SiteSet does not find sites
- Removed setting global unicore registry

* Thu Aug 30 2012 Emir Imamagic <eimamagi@srce.hr> - 0.90.11-1
- Nagios doesn't test services which aren't in production
  https://tomtools.cern.ch/jira/browse/SAM-2878

* Fri Jul 27 2012 Emir Imamagic <eimamagi@srce.hr> - 0.90.10-1
- Review NCG for ops-monitor
  https://tomtools.cern.ch/jira/browse/SAM-1430
- Set ismonitored=on on all ATP URLs
  https://tomtools.cern.ch/jira/browse/SAM-2867
- Skip configuration of sites without services
  https://tomtools.cern.ch/jira/browse/SAM-2862
- Integrate UNICORE Job and unicore6.StorageFactory
  https://tomtools.cern.ch/jira/browse/SAM-2722
- Configure UNICORE tests to use local registry
  https://tomtools.cern.ch/jira/browse/SAM-2859

* Sun Jul 22 2012 Emir Imamagic <eimamagi@srce.hr> - 0.90.4-1
- Integrate QCG/MAPPER probes
  https://tomtools.cern.ch/jira/browse/SAM-2721

* Wed Jul 18 2012 Paloma Fuente <pfuentef@cern.ch> - 0.90.3-1
- Enable MRS metrics
  https://tomtools.cern.ch/jira/browse/SAM-2346
- Support multiple email addresses from GOCDB
  https://tomtools.cern.ch/jira/browse/SAM-2782
  
* Tue Jul 17 2012 Emir Imamagic <eimamagi@srce.hr> - 0.90.1-1
- ncg error parsing JSON response on sam-nagios
  https://tomtools.cern.ch/jira/browse/SAM-2778

* Wed Jul 11 2012 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.89.8-1
- Replaced MIG::Message with Messaging::Message
  https://tomtools.cern.ch/jira/browse/SAM-2444

* Wed Jun 13 2012 Emir Imamagic <eimamagi@srce.hr> - 0.89.7-1
- NCG does not generate VO_FQAN metrics with POEM
  https://tomtools.cern.ch/jira/browse/SAM-2730

* Mon Jun 11 2012 Emir Imamagic <eimamagi@srce.hr> - 0.89.4-1
- Sanity check probe for NCG
  https://tomtools.cern.ch/jira/browse/SAM-2435

* Mon Jun 11 2012 Emir Imamagic <eimamagi@srce.hr> - 0.89.3-1
- NCG does not generate VO_FQAN metrics with POEM
  https://tomtools.cern.ch/jira/browse/SAM-2730
- ncg fails on sam-nagios fresh install
  https://tomtools.cern.ch/jira/browse/SAM-2729  

* Thu May 31 2012 Emir Imamagic <eimamagi@srce.hr> - 0.89.1-1
- Modify ncg.pl to allow overriding site-level NCG::ConfigGen::Nagios blocks
  https://tomtools.cern.ch/jira/browse/SAM-2161

* Thu Apr 5 2012 Emir Imamagic <eimamagi@srce.hr> - 0.88.8-1
- Add script for converting Hash_local.pm to JSON
  https://tomtools.cern.ch/jira/browse/SAM-2613
- ncg: fails to configure vo nagios (lhcb specific issue)
  https://tomtools.cern.ch/jira/browse/SAM-2607
  
* Tue Mar 27 2012 Emir Imamagic <eimamagi@srce.hr> - 0.88.6-1
- NCG should not publish configuration to 
  /var/spool/nagios2metricstore/config
  https://tomtools.cern.ch/jira/browse/SAM-2570

  * Tue Mar 27 2012 Emir Imamagic <eimamagi@srce.hr> - 0.88.4-1
- Obsoleted metric related localdb options
  https://tomtools.cern.ch/jira/browse/SAM-2565
- New bootstrapping from POEM
  https://tomtools.cern.ch/jira/browse/SAM-2434

* Wed Mar 21 2012 Emir Imamagic <eimamagi@srce.hr> - 0.88.3-1
- Remove ch.cern.sam.POEMSync on site instances
  https://tomtools.cern.ch/jira/browse/SAM-2533
- NCG uses incorrect topic names for configs
  https://tomtools.cern.ch/jira/browse/SAM-2534

* Tue Mar 20 2012 Emir Imamagic <eimamagi@srce.hr> - 0.88.2-1
- NCG modifications related to sam-sync
  https://tomtools.cern.ch/jira/browse/SAM-2522
- Remove DownCollector modules from NCG
  https://tomtools.cern.ch/jira/browse/SAM-2513
- Remove MDDB module from NCG
  https://tomtools.cern.ch/jira/browse/SAM-251

* Wed Feb 22 2012 Emir Imamagic <eimamagi@srce.hr> - 0.88.1-1
- Remove ATP, MDDB and MRS sync calls from ncg.reload.sh
  https://tomtools.cern.ch/jira/browse/SAM-2136
- Remove SAM topology module
  https://tomtools.cern.ch/jira/browse/SAM-2475  
- remove calls to 'org.egee.MrsCheckMissingProbes'
  https://tomtools.cern.ch/jira/browse/SAM-2474
- add call to MRS bootstrapper in /usr/sbin/ncg.reload.sh
  https://tomtools.cern.ch/jira/browse/SAM-2473
- ncg: probe/metric configuration via common configuration file   
  https://tomtools.cern.ch/jira/browse/SAM-2445
  
* Tue Jan 31 2012 Emir Imamagic <eimamagi@srce.hr> - 0.87.3-1
- Incorrect URLs used by NCG::SiteContacts::ATP
  https://tomtools.cern.ch/jira/browse/SAM-2376

* Tue Jan 31 2012 Emir Imamagic <eimamagi@srce.hr> - 0.87.2-1
- ncg failure with error about missing contact
  https://tomtools.cern.ch/jira/browse/SAM-2357

* Thu Nov 10 2011 Emir Imamagic <eimamagi@srce.hr> - 0.87.1-1
- NCG::SiteInfo::GOCDB to read HOSTDN
  https://tomtools.cern.ch/jira/browse/SAM-2162
- Modify ncg.pl to invoke LocalMetricsAttrs::File for 'nagios' site 
  https://tomtools.cern.ch/jira/browse/SAM-2160
- Add support for SCOPE in NCG::SiteInfo::GOCDB
  https://tomtools.cern.ch/jira/browse/SAM-2285
- NCG::SiteSet::GOCDB should not stop if UNICORE registry does not exist
  https://tomtools.cern.ch/jira/browse/SAM-2324
- Update NCG to take input data sources from ATP
  https://tomtools.cern.ch/jira/browse/SAM-2119
- atp warning about voms causes yaim run to fail
  https://tomtools.cern.ch/jira/browse/SAM-2351

* Thu Nov 10 2011 Emir Imamagic <eimamagi@srce.hr> - 0.87.0-1
- NCG generates incorrect UNICORE configuration
  https://tomtools.cern.ch/jira/browse/SAM-2258
- NCG shouldn't call old SAM PI to get metric results
  https://tomtools.cern.ch/jira/browse/SAM-2155
- NCG - adjust to modified web service 'atp/api/search/vofeeds'
  https://tomtools.cern.ch/jira/browse/SAM-2232

* Sat Oct 22 2011 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.86.2-1
- NCG should create /var/log/unicore/* subdirectories only if
  ENABLE_UNICORE_PROBES is set
  https://tomtools.cern.ch/jira/browse/SAM-2068
- Move ARC metrics to default profile
  https://tomtools.cern.ch/jira/browse/SAM-2066
- Make UNICORE metrics VO-independent
  https://tomtools.cern.ch/jira/browse/SAM-2086
* Tue Oct 18 2011 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.86.1-1
- Renamed org.sam.sec probes to eu.egi.sec
- Fixed CRL probe path issue
  https://tomtools.cern.ch/jira/browse/SAM-2023
* Mon Oct 10 2011 Marian Babik <marian.babik@cern.ch> - 0.85.1-1
- Minor fixes for adding poem_sync probe
  https://tomtools.cern.ch/jira/browse/SAM-2006
* Wed Oct 05 2011 Marian Babik <marian.babik@cern.ch> - 0.84.1-1
- Add check_poem_sync probe
  https://tomtools.cern.ch/jira/browse/SAM-2006
* Fri Sep 30 2011 Emir Imamagic <eimamagi@srce.hr> - 0.83.1-1
- Enable using SITE_BDII attribute on site instance
  https://tomtools.cern.ch/jira/browse/SAM-1993
- Add ncg.pl argument for definition of output directory
  https://tomtools.cern.ch/jira/browse/SAM-1996
- Service ncg must kill all remaining processes
  https://tomtools.cern.ch/jira/browse/SAM-1744
- NCG should store configuration in new directory
  https://tomtools.cern.ch/jira/browse/SAM-1689
- NCG must check if there is a running instance
  https://tomtools.cern.ch/jira/browse/SAM-1688

* Fri Sep 16 2011 Emir Imamagic <eimamagi@srce.hr> - 0.82.4-1
- Remove org.sam.WN-CAver metric from all profiles
  https://tomtools.cern.ch/jira/browse/SAM-1930

* Fri Sep 16 2011 Emir Imamagic <eimamagi@srce.hr> - 0.82.3-1
- Integration of UNICORE probes into SAM
  https://tomtools.cern.ch/jira/browse/SAM-1423

* Tue Sep 06 2011 Wojciech Lapka <wojciech.lapka@cern.ch> - 0.82.1-1
- New MRS probes for ops-monitor:
  https://tomtools.cern.ch/jira/browse/SAM-1878

* Sat Aug 13 2011 Emir Imamagic <eimamagi@srce.hr> - 0.81.2-1
- Support failver nagios - configurable hot-standby mode
  https://tomtools.cern.ch/jira/browse/SAM-1127
- Enable modification of notification options
  https://tomtools.cern.ch/jira/browse/SAM-1006
- Enable switching on notifications on level of hostgroups and hosts
  https://tomtools.cern.ch/jira/browse/SAM-1424

* Fri Jul 22 2011 Emir Imamagic <eimamagi@srce.hr> - 0.81.1-1
- Bug in LocalMetricsAttrs/LDAP.pm
  https://tomtools.cern.ch/jira/browse/SAM-1657
- NCG::SiteInfo::ATP incorrectly processes vo names
  https://tomtools.cern.ch/jira/browse/SAM-1739
- Enable removing metric from an alias on host with multiple aliases
  https://tomtools.cern.ch/jira/browse/SAM-1645
- ncg.reload.sh should call ncg with a timeout
  https://tomtools.cern.ch/jira/browse/SAM-702

* Mon Jun 27 2011 Emir Imamagic <eimamagi@srce.hr> - 0.80.1-1
- perl(JSON) dependency of egee-NAGIOS
  https://tomtools.cern.ch/jira/browse/SAM-1626

* Fri May 20 2011 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.79.2-1
- Add RDSModuleCheck to security nodetype
  https://tomtools.cern.ch/jira/browse/SAM-1569

* Fri Apr 29 2011 Emir Imamagic <eimamagi@srce.hr> - 0.79.1-1
- Add metrics for Globus5 services
  https://tomtools.cern.ch/jira/browse/SAM-1494
- Add new metrics to NGI profile
  https://tomtools.cern.ch/jira/browse/SAM-1517
- Enable setting GOCDB URL in Yaim
  https://tomtools.cern.ch/jira/browse/SAM-1475
- Remove metric org.ggus.Tickets
  https://tomtools.cern.ch/jira/browse/SAM-1518
- Set default URLs for CA probe to EGI repo
  https://tomtools.cern.ch/jira/browse/SAM-1420
- Change ROC-EXTRAS profile name to ROCEXTRAS
  https://tomtools.cern.ch/jira/browse/SAM-1422
- Hash.pm - change the help URLs for "org.sam.*" probes
  https://tomtools.cern.ch/jira/browse/SAM-1290

* Mon Apr 18 2011 Emir Imamagic <eimamagi@srce.hr> - 0.78.5-1
- Add gLExec service to glexec profile in Hash.pm
  https://tomtools.cern.ch/jira/browse/SAM-1354

* Fri Apr 1 2011 Emir Imamagic <eimamagi@srce.hr> - 0.78.4-1
- syntax error in ncg.reload.sh
  https://tomtools.cern.ch/jira/browse/SAM-1394

* Wed Mar 30 2011 Emir Imamagic <eimamagi@srce.hr> - 0.78.3-1
- ncg.reload.sh fails when Nagios is not running
  https://tomtools.cern.ch/jira/browse/SAM-1386
* Tue Mar 22 2011 Emir Imamagic <eimamagi@srce.hr> - 0.78.2-1
- Add gLExec service to ROC and NGI profile in Hash.pm
  https://tomtools.cern.ch/jira/browse/SAM-1354

* Fri Feb 11 2011 Emir Imamagic <eimamagi@srce.hr> - 0.78.1-1
- Add ARC probes documentation
  https://tomtools.cern.ch/jira/browse/SAM-1317
- SiteContacts::GOCDB module should use site's ROC
  https://tomtools.cern.ch/jira/browse/SAM-1353
- NCG/yaim parameter for message broker configuration
  https://tomtools.cern.ch/jira/browse/SAM-1146
- NCG throws error and stops execution when site has no 
  services and ATP used as topology provider
  https://tomtools.cern.ch/jira/browse/SAM-1271
- ncg.reload.sh uses hardcoded timeout for atp and mddb sync
  https://tomtools.cern.ch/jira/browse/SAM-1333

* Fri Feb 11 2011 Emir Imamagic <eimamagi@srce.hr> - 0.77.6-1
- Add ismonitored flag to URL
  https://tomtools.cern.ch/jira/browse/SAM-1270

* Wed Feb 9 2011 Emir Imamagic <eimamagi@srce.hr> - 0.77.5-1
- Remove metric hr.srce.CAdist-Version from all profiles
  https://tomtools.cern.ch/jira/browse/SAM-1252

* Thu Feb 3 2011 Emir Imamagic <eimamagi@srce.hr> - 0.77.4-1
- Change links for CADist probe
  https://tomtools.cern.ch/jira/browse/SAM-1236
- Remove metric org.arc.RLS from ARC profile
  https://tomtools.cern.ch/jira/browse/SAM-1235

* Wed Feb 2 2011 Christos Triantafyllidis <ctria@grid.aith.gr> - 0.77.3-1
- Added Torque check for security profile at Hash.pm
  https://tomtools.cern.ch/jira/browse/SAM-1220
- Mapped arc profile to ARC

* Tue Feb 1 2011 Emir Imamagic <eimamagi@srce.hr> - 0.77.2-1
- Validation of MPI services
  https://tomtools.cern.ch/jira/browse/SAM-1152
- Added doc links to org.egee.MrsCheckMissingProbes
  and org.nagios.NCGPidFile

* Tue Jan 4 2011 Emir Imamagic <eimamagi@srce.hr> - 0.77.1-1
- Enable robot certs in NCG
  https://tomtools.cern.ch/jira/browse/SAM-1115
- Define VO profile with only VO-dependent metrics
  https://tomtools.cern.ch/jira/browse/SAM-1178
- Adding subgrid support to NCG::SiteSet::GOCDB
  https://tomtools.cern.ch/jira/browse/SAM-1112
- Enable changing of Nagios notifications header
  https://tomtools.cern.ch/jira/browse/SAM-1125
- Change GOCDB address to goc.egi.eu
  https://tomtools.cern.ch/jira/browse/SAM-1160
- Map ARC-CE services to ArcCE
  https://tomtools.cern.ch/jira/browse/SAM-1138  

* Sat Dec 4 2010 Emir Imamagic <eimamagi@srce.hr> - 0.76.2-2
- Nagios_BDII_entry and Queue_BDII_entry failing for new versions
  https://tomtools.cern.ch/jira/browse/SAM-915
- org.nagios.MsgToHandlerPidFile : msg-to-handler PID has moved
  https://tomtools.cern.ch/jira/browse/SAM-1020
- added /var/run/ncg directory for pid file
- Add ncg check
  https://tomtools.cern.ch/jira/browse/SAM-980
- Enable adding metrics to profile via localdb
  https://tomtools.cern.ch/jira/browse/SAM-945

* Sat Dec 4 2010 Emir Imamagic <eimamagi@srce.hr> - 0.76.1-3
- Modifying NCG::LocalMetrics::Hash to import local changes from a separate file
  https://tomtools.cern.ch/jira/browse/SAM-974

* Tue Nov 30 2010 Wojciech Lapka <wojciech.lapka@cern.ch> - 0.75.2-3
- Enable nagios check org.egee.MrsCheckMissingProbes
  https://tomtools.cern.ch/jira/browse/SAM-764

* Sat Nov 27 2010 Emir Imamagic <eimamagi@srce.hr> - 0.75.2-1
- SiteInfo::ATP module should report error on empty result
  https://tomtools.cern.ch/jira/browse/SAM-968

* Wed Nov 3 2010 Emir Imamagic <eimamagi@srce.hr> - 0.75.1-1
- Add VO filter to module NCG::SiteInfo::LDAP
  https://tomtools.cern.ch/jira/browse/SAM-936
- NCG::SiteInfo::LDAP doesn't fetch correct info for SRM nodes
  https://tomtools.cern.ch/jira/browse/SAM-849
- Enable glexec tests on CREAM-CE
  https://tomtools.cern.ch/jira/browse/SAM-935
- CA distribution test
  https://tomtools.cern.ch/jira/browse/SAM-877
- Integrate ARC probes into SAM/Nagios
  https://tomtools.cern.ch/jira/browse/SAM-751
- Add hack to translate ops to ops.ndgf.org for ARC-CEs
  https://tomtools.cern.ch/jira/browse/SAM-925
- add hr.srce.GoodSEs metric to Hash.pm
  https://tomtools.cern.ch/jira/browse/SAM-917
- ncg.pl should leave backup directory if the new directory doesn't exist
  https://tomtools.cern.ch/jira/browse/SAM-924
- Add the new probe for monitoring syslog for errors from
  SAM Nagios probes and plugins
  https://tomtools.cern.ch/jira/browse/SAM-896
- Allow VO_FQAN to be VO
  https://tomtools.cern.ch/jira/browse/SAM-899
- Include patches which enable web proxies
  https://tomtools.cern.ch/jira/browse/SAM-895

* Fri Oct 29 2010 Emir Imamagic <eimamagi@srce.hr> - 0.74.3-1
- Switched off org.egee.MrsCheckMissingProbes

* Thu Oct 21 2010 Emir Imamagic <eimamagi@srce.hr> - 0.74.2-1
- CaDist syslog errors
  https://tomtools.cern.ch/jira/browse/SAM-874

* Thu Sep 30 2010 Emir Imamagic <eimamagi@srce.hr> - 0.74.1-1
- Added example of configuration for VO boxes based on ATP
  in file ncg.atpvo.conf.
- How to configure a Nagios box with the services described in an ATP VO topology feed
  https://tomtools.cern.ch/jira/browse/SAM-832
- nagios.cmd - file monitoring is needed
  https://tomtools.cern.ch/jira/browse/SAM-625
- Change the default DownCollector address from ccenoc.in2p3.fr to net.egi.eu
  https://tomtools.cern.ch/jira/browse/SAM-848
- Fixed LocalMetrics::File options don't work on nagios host
  https://tomtools.cern.ch/jira/browse/SAM-840
- Fixed Enable nagios check org.egee.MrsCheckMissingProbes
  https://tomtools.cern.ch/jira/browse/SAM-764
- Fixed Nagios Notification: ADD_SERVICECONTACT doesn't work
  https://tomtools.cern.ch/jira/browse/SAM-816
- Fixed Enable removal of remote metrics
  https://tomtools.cern.ch/jira/browse/SAM-454

* Mon Sep 20 2010 Emir Imamagic <eimamagi@srce.hr> - 0.73.2-1
- Fixed Problem with NCG after adding more data to header of Config messages.
  https://tomtools.cern.ch/jira/browse/SAM-788
- NCG::SiteSet::LDAP extracts EGI_NGI information
- Fixed APEL Check Doc links wrong
  https://tomtools.cern.ch/jira/browse/SAM-782
- Fixed REMOVE_CONTACT doesn't work
  https://tomtools.cern.ch/jira/browse/SAM-730

* Fri Sep 17 2010 K.Skaburskas <konstantin.skaburskas@cern.ch> - 0.72.8-1
- Added "--err-topics lcg_util,default" param to SRM-All in Hash.pm (SAM-797)

* Fri Sep 03 2010 James Casey <james.casey@cern.ch> - 0.72.7-1
- Publish message headers in config messagesm (MIG-130)

* Mon Aug 30 2010 Wojciech Lapka <wojciech.lapka@cern.ch> - 0.72.6-1
- ncg error in ConfigConverter.pm (SAM-763)

* Fri Aug 27 2010 Wojciech Lapka <wojciech.lapka@cern.ch> - 0.72.5-1
- disable APEL tests (SAM-769)

* Thu Aug 26 2010 Emir Imamagic <eimamagi@srce.hr> - 0.72.4-1
- reverted SAM-702
- Enable Freshness Checks for site and top-level BDIIs
  https://tomtools.cern.ch/jira/browse/SAM-741

* Tue Aug 24 2010 Emir Imamagic <eimamagi@srce.hr> - 0.72.3-1
- modified definition of hr.srce probes
  https://tomtools.cern.ch/jira/browse/SAM-555
- Publish config to special dirqueue for mrs-load-services
  https://tomtools.cern.ch/jira/browse/SAM-752

* Tue Aug 10 2010 Emir Imamagic <eimamagi@srce.hr> - 0.72.2-1
- ncg.reload.sh should call ncg with a timeout
  https://tomtools.cern.ch/jira/browse/SAM-702
- Removed obsolete srce.hr probes configs
  https://tomtools.cern.ch/jira/browse/SAM-740
- ch.cern.FTS-InfoSites should not check for LB hosts
  https://tomtools.cern.ch/jira/browse/SAM-480
- Fixed APEL config for CREAM-CEs
  https://tomtools.cern.ch/jira/browse/SAM-500
- NCG should put messages directly in the outgoing queue rather than in config.db
  https://tomtools.cern.ch/jira/browse/SAM-725
- Changed ncg init.d level
  https://tomtools.cern.ch/jira/browse/SAM-731
- Fixed REMOVE_CONTACT doesn't work
  https://tomtools.cern.ch/jira/browse/SAM-730
- NCG doesn't remove hr.srce.MyProxy-ProxyLifetime for PROBES_TYPE remote
  https://tomtools.cern.ch/jira/browse/SAM-728
- Fixed Problem with notification sent to NAGIOS_ADMIN
  https://tomtools.cern.ch/jira/browse/SAM-720

* Tue Aug 3 2010 Wojciech Lapka <wojciech.lapka@cern.ch> - 0.71.7-1
- NCG calling SAM PI - spread the load for 1 hour.

* Mon Aug 2 2010 Emir Imamagic <eimamagi@srce.hr> - 0.71.6-1
- Removed NOHOSTNAME flag on SAM monits.

* Fri Jul 30 2010 Emir Imamagic <eimamagi@srce.hr> - 0.71.5-1
- Fixed Several NAGIOS metrics incorrectly configured
  https://tomtools.cern.ch/jira/browse/SAM-695

* Fri Jul 30 2010 Emir Imamagic <eimamagi@srce.hr> - 0.71.4-1
- Fixed hr.srce.MyProxy-ProxyLifetime fails
  https://tomtools.cern.ch/jira/browse/SAM-694

* Wed Jul 28 2010 Emir Imamagic <eimamagi@srce.hr> - 0.71.3-1
- Removed templates.
- Remove passive metrics if parent is not present
  https://tomtools.cern.ch/jira/browse/SAM-681
- Enabled multiple proxies per VO
  https://tomtools.cern.ch/jira/browse/SAM-668
- Implemented Move metrics from templates to Hash
  https://tomtools.cern.ch/jira/browse/SAM-548
- Implemented variable for disabling SendToMsg
  https://tomtools.cern.ch/jira/browse/SAM-511
- Fixed ncg.reload.sh - detect failures of DB components
  https://tomtools.cern.ch/jira/browse/SAM-665
- Implemeted Disable msg-contacts if GGUS and Dashboard integration is disabled
  https://tomtools.cern.ch/jira/browse/SAM-676
- Implemented Remove wlcg_resource.cfg file
  https://tomtools.cern.ch/jira/browse/SAM-652
- Implemented Allow an extra contact for a service. In particular the proxy in myproxy lifetime.
  https://tomtools.cern.ch/jira/browse/SAM-132
- Implemented checking healthiness of msg-to-queue
  https://tomtools.cern.ch/jira/browse/SAM-568
- Implemented The org.egee.CheckConfig check is no longer needed
  https://tomtools.cern.ch/jira/browse/SAM-641
- Implemented hr.srce.GoodCEs should generate file to /var/lib/gridprobes
  https://tomtools.cern.ch/jira/browse/SAM-642

* Fri Jul 2 2010 Emir Imamagic <eimamagi@srce.hr> - 0.71.1-1
- Fixed NCG doesn't generate aliases properly
  https://tomtools.cern.ch/jira/browse/SAM-643
- Fixed ncg service should log ncg.reload.sh call
  https://tomtools.cern.ch/jira/browse/SAM-623

* Fri Jun 25 2010 Emir Imamagic <eimamagi@srce.hr> - 0.70.10-1
- SAM-614: ncg.reload.sh should run sync as nagios to allow for permissions on log files
* Fri Jun 25 2010 Emir Imamagic <eimamagi@srce.hr> - 0.70.9-1
- Fixed ncg.reload.sh should check if MRS is used
  https://tomtools.cern.ch/jira/browse/SAM-584
- Fixed Duplicate service definitions on site profile
  https://tomtools.cern.ch/jira/browse/SAM-585

* Fri Jun 25 2010 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.70.8-1
- Added documentation URL for the org.sam.sec probes
  https://tomtools.cern.ch/jira/browse/SAM-578

* Wed Jun 23 2010 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.70.7-2
- Added definition of the probes for the security monitoring probes
  (grid-monitoring-probes-org.sam.sec) in Hash module of LocalMetrics
  and a definition of a babysitting check for the relevant CE checks
  https://tomtools.cern.ch/jira/browse/SAM-570

* Thu Jun 17 2010 Emir Imamagic <eimamagi@srce.hr> - 0.70.6-1
- Fixed Removing a service check for an alias does not remove
  service check of individual LB hosts.
  https://tomtools.cern.ch/jira/browse/SAM-484
- Added configuration for check #files (or size) of the
  /var/spool/msg-nagios-bridge and /var/spool/nagios2metricstore
  https://tomtools.cern.ch/jira/browse/SAM-121
- NCG compliant to new ATP JSON
  https://tomtools.cern.ch/jira/browse/SAM-525
- Configure check_ggus withing NCG.
  https://tomtools.cern.ch/jira/browse/SAM-175
- Added timeout parameter to ncg.pl
  https://tomtools.cern.ch/jira/browse/SAM-457
- Enable configuration files in directory
  https://tomtools.cern.ch/jira/browse/SAM-505
- Fixed NCG doesn't clean configuration files in /etc/wlcg.d
  Single & multi site instance have the same output directory
  NCG moves existing output directory to directory with suffix .ncg.backup
  https://tomtools.cern.ch/jira/browse/SAM-47
- Added ncg.reload.sh cronjob
  Added new mrs_load_services script
  https://tomtools.cern.ch/jira/browse/SAM-402
- Pnp commands generated by ncg should use different name from default
  https://tomtools.cern.ch/jira/browse/SAM-343
- Cronjob ncg.reload.sh exits 1 when regeneration failes
- Service ncg catches ncg.reload.sh exit status

* Wed Jun 16 2010 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.70.2-1
- Added the CRL validity check for Nagios node even when NRPE-UI is used.
  https://tomtools.cern.ch/jira/browse/SAM-5

* Wed Jun 16 2010 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.70.1-1
- Added a CRL validity check for Nagios node (org.sam.sec.CRLs)
  https://tomtools.cern.ch/jira/browse/SAM-5

* Mon May 31 2010 Emir Imamagic <eimamagi@srce.hr> - 0.69.1-1
- Fixed Add timeout variable to SAM and other HTTP modules
  https://tomtools.cern.ch/jira/browse/SAM-522
- Fixed NCG doesn't create msg bridge tests for remote config
  https://tomtools.cern.ch/jira/browse/SAM-506
- Fixed NCG doesn't create host def for myproxy.cern.ch
  https://tomtools.cern.ch/jira/browse/SAM-493
- Fixed INCLUDE_LB_NODE = 0 in ncg.conf is ignored.
  https://tomtools.cern.ch/jira/browse/SAM-486

* Tue May 18 2010 Emir Imamagic <eimamagi@srce.hr> - 0.68.1-1
  https://tomtools.cern.ch/jira/browse/SAM-486

* Thu May 06 2010 Emir Imamagic <eimamagi@srce.hr> - 0.67.1-1
- ncg exits in case when any of modules reports error
- Added PNP links to sam CE, CREAM and WMS Job-Monits
  https://tomtools.cern.ch/jira/browse/SAM-475

* Mon May 03 2010 Lionel Cons <lionel.cons@cern.ch> - 0.66.1-1
- Replaced msg-to-queue by msg-to-handler

* Fri Apr 23 2010 Emir Imamagic <eimamagi@srce.hr> - 0.65.1-1
- Added WHITELIST_FILE for RemoteMetrics::SAM

* Tue Apr 20 2010 Christos Triantafyllidis <ctria@grid.auth.gr> - 0.64.1-1
- Removed old SEE SAM templates
  https://savannah.cern.ch/bugs/?66189
- Added a babysitter definition for org.sam.sec probes
  https://savannah.cern.ch/bugs/?66190

* Fri Mar 19 2010 Emir Imamagic <eimamagi@srce.hr> - 0.63.1-1
- HTTP requests should use GET for GOCDB calls
  https://savannah.cern.ch/bugs/?65727
- Enable removal of remote metrics
  https://savannah.cern.ch/bugs/?65719
- ncg.pl fails on site instances with LB nodes
  https://savannah.cern.ch/bugs/?65645
- added services info to metrics in ConfigCache
- NCG - provide information to MRS
  https://savannah.cern.ch/bugs/?64960
- definition of metric parameters via ncg.localdb
  https://savannah.cern.ch/bugs/?64607
- Added HOSTNAME option to NCG::RemoteMetrics::Nagios for filtering
  Nagios servers from where results will be imported
- Added SEND_TO_EMAIL to NCG::ConfigGen::Nagios
  https://savannah.cern.ch/bugs/?42603
- Additional Info link not a full URI
  https://savannah.cern.ch/bugs/?64630
- Removed obsoleted perl JSON calls (added dep)
  https://savannah.cern.ch/bugs/?64597
- Removed checkPing, hosts are either checked via ping
  or not checked at all.
  https://savannah.cern.ch/bugs/?42336

* Fri Mar 19 2010 Emir Imamagic <eimamagi@srce.hr> - 0.62.1-1
- Added LDAP_CONNECT_TIMEOUT to all LDAP modules (default 10s)
- Fixed https://savannah.cern.ch/bugs/index.php?64598
- Email notifications are nicer now (https://savannah.cern.ch/bugs/index.php?64341)
- msg-to-queue should not be configured on ops-monitor nagios
  https://savannah.cern.ch/bugs/index.php?64544

* Thu Mar 18 2010 Emir Imamagic <eimamagi@srce.hr> - 0.61.1-1
- Added attribute VO_FQAN to org.sam.SRM-All.

* Thu Mar 18 2010 Emir Imamagic <eimamagi@srce.hr> - 0.60.1-1
- ops-monitor conf changed
- Changed profile roc to ROC_EXTRAS.
- Changed VO_FQAN logic to have default and per profile ones.
- Integrated SAM ROC profile into Hash.pm.
- Defined profiles for roles with capital letters.

* Thu Mar 18 2010 Emir Imamagic <eimamagi@srce.hr> - 0.59.1-1
- Fixed missing vo for GridProxy-Get.
- Fixed generation of non-vo dependent metrics.

* Thu Mar 18 2010 Emir Imamagic <eimamagi@srce.hr> - 0.58.1-1
- Fixed filtering of SAM babysitters for multisites.

* Wed Mar 17 2010 Emir Imamagic <eimamagi@srce.hr> - 0.57.1-1
- Invoke LocalMetricsAttrs after other module in NCG.
- ops monitor probe changed
- Moved retrieving contact info to SiteContacts module.
  (https://savannah.cern.ch/bugs/index.php?64354)
- Added new SiteContacts module LDAP.
- Enabled defining vo as VO_FQAN.
- Fixed filtering of SAM babysitters.
- Notifications are repeated every 24h.

* Tue Mar 16 2010 Emir Imamagic <eimamagi@srce.hr> - 0.56.1-2
- Added VO_FQAN parameter to LocalMetrics::Hash
- Added filtering of metrics based on VO_FQAN in ConfigGen::Nagios
- Added X509_USER_PROXY to ch.cern.FTS-InfoSites
- Added support for multiple FQANs for same VO
- Cleared up LocalMetricsAttrs::Active
- GGUS ticket #63325

* Thu Mar 04 2010 Emir Imamagic <eimamagi@srce.hr> - 0.55.1-1
- Removed unmonitored services from SiteInfo::SAM.

* Wed Mar 03 2010 Emir Imamagic <eimamagi@srce.hr> - 0.54.1-1
- Added ENABLE_FLAP_DETECTION for flapping config control.
- Enabled all notifications for MSG contacts.
- Added --vo to hr.srce.VOMS-ServiceStatus.

* Tue Mar 02 2010 Emir Imamagic <eimamagi@srce.hr> - 0.53.1-1
- Added more params for org.sam.MPI tests

* Tue Mar 02 2010 Emir Imamagic <eimamagi@srce.hr> - 0.52.1-1
- Added org.sam.MPI tests

* Fri Feb 26 2010 Romain <Romain.Wartel@cern.ch> 0.51.1-1
- Added script to list and/or resend notifications sent to the MSG

* Wed Feb 24 2010 Romain <Romain.Wartel@cern.ch> 0.50.1-1
- Added ACK for Dashboard notifications
- Enabled flap detection.
- OPS-monitor configuration changed
- Take better care with dependencies of VO dependent metrics.
- Implemented better VO filtering (LFC_L case).

* Thu Feb 18 2010 Wojciech Lapka <Wojciech.Lapka@cern.ch> - 0.49.1-1
- SAM PI: Use services_per_vo_monitored.jsp, service_types_per_service_endpoint_monitored.jsp.

* Wed Feb 17 2010 Emir Imamagic <eimamagi@srce.hr> - 0.48.1-1
- Move hr.srce.GoodCEs to NRPE UI.
- Added Local-LFC service analysis.
- Added glexec probes.

* Wed Feb 9 2010 Emir Imamagic <eimamagi@srce.hr> - 0.47.1-1
- If native type is defined, switch on local.
- Fixed generation of NRPE config.
- super Nagios service check modified

* Mon Feb 8 2010 Steve Traylen <steve.traylen@cern.ch> - 0.46.1-2
- Release bump since built allready.

* Fri Feb 5 2010 Emir Imamagic <eimamagi@srce.hr> - 0.46.1-1
- Changed MDDB to fetch per profile config.

* Fri Feb 5 2010 Emir Imamagic <eimamagi@srce.hr> - 0.45.1-1
- Added an NCG configuration variable to force the use of check_ping
  even the hosts are not pingable at configuration time
- Apache 2.0 license
- Added support for VO_FQAN option in ConfigGen::Nagios
- Fixed https://savannah.cern.ch/bugs/?61289
- Removed DB methods from all GOCDB modules.
- Added ROC information to SiteDB.
- Attribute _roc in generated config is set from SiteDB.
- Added checks for central monitoring of Nagioses and ActiveMQ Brokers.
- Added INCLUDE_MSG_CHECKS for filtering out checks for MSG interaction.
- Added INCLUDE_PROXY_CHECKS for filtering out checks for proxy management.
  (ConfigGen::Nagios)
- NAGIOS_ROLE can have any value.
- Switch to subroutine to_json.
- Committed fix for http://savannah.cern.ch/bugs/?62019
- Added host cert/key to SRM2-CertLifetime.
- Add list of contacts in case of comma separated list. (SiteInfo::LDAP)
- Check if MYPROXY_SERVER is defined when proxy checks are included.
- For sites set org.nmap.GRAM as metric for GoodCEs.

* Tue Dec 15 2009 Emir Imamagic <eimamagi@srce.hr> - 0.44.1-1
- Cleared up SAM checks definitions.

* Tue Dec 15 2009 Emir Imamagic <eimamagi@srce.hr> - 0.43.1-1
- Typo.
* Tue Dec 15 2009 Emir Imamagic <eimamagi@srce.hr> - 0.42.1-1
- CE & SE NPRE Process checks removed from site profile.
- Corrected -m and --vo parameters for LFC probes.

* Tue Dec 15 2009 Emir Imamagic <eimamagi@srce.hr> - 0.41.1-1
- Removed "local" metrics, all metrics are now native.
- Updated ch.cern.LFC definition.
- Corrected ch.cern.FTS-ChannelList parameter.

* Mon Dec 14 2009 Emir Imamagic <eimamagi@srce.hr> - 0.40.1-1
- Corrected hr.srce.CREAMCE-CertLifetime & hr.srce.RGMA-CertLifetime
  to use globus cert for AuthN.

* Mon Dec 14 2009 Emir Imamagic <eimamagi@srce.hr> - 0.39.1-1
- Fixed sudouser custom variable in commands.
- Added org.sam.WN-PyVer.
- Transform CREAMCE to CREAM-CE in SiteInfo::SAM.

* Mon Dec 14 2009 Emir Imamagic <eimamagi@srce.hr> - 0.38.1-1
- Enabled setting sudo user via SUDO flag.
- Corrected definition of SCAS check.

* Mon Dec 14 2009 Emir Imamagic <eimamagi@srce.hr> - 0.37.1-1
- Defined correct parent for org.sam.WN tests.
* Mon Dec 14 2009 Emir Imamagic <eimamagi@srce.hr> - 0.36.1-1
- Added org.egee.SCAS-Check.
- Added definition of org.sam.CREAMCE and org.sam.CREAMCE-Direct checks.
- Added definition of org.sam.WMS checks.
- Removed hr.srce.ResourceBroker-RunJob and hr.srce.WMProxy-RunJob.
- Associated check org.nagios.GridFTP-ProcessCheck with CE and SRM on site profile.
- Added support for NRPE check on service nodes (NRPE_SERVICE flag).
- Added new localdb options:
  GLOBAL_ATTRIBUTE!name!value
  VO_GLOBAL_ATTRIBUTE!VO!name!value
  VO_ATTRIBUTE!VO!name!value
  VO_HOST_ATTRIBUTE!host!VO!name!value
  VO_SERVICE_ATTRIBUTE!service!VO!name!value
- Apache 2.0 license.
- Removed GHA modules and LocalMetricSets.
- Store all metrics found by Hash and MDDB to MetricCollection.
- Enable adding of metrics from MDDB or Hash via localdb (https://savannah.cern.ch/bugs/?59551).
- Added --err-topics ce_wms to org.sam.CE-JobSubmit.

* Thu Nov 12 2009 Emir <eimamagi@srce.hr> - 0.35.1-1
  Added attribute ROC which sets _roc custom variable in service definitions.
  https://savannah.cern.ch/bugs/index.php?58604
* Tue Oct 26 2009 Emir <eimamagi@srce.hr> - 0.34.1-1
  Add gstat-validate-site probe
  https://savannah.cern.ch/bugs/?58488
* Tue Oct 26 2009 Emir <eimamagi@srce.hr> - 0.33.1-1
- Adjust timeouts and frequency of atp and mddb probes.
* Mon Oct 26 2009 Emir <eimamagi@srce.hr> - 0.32.1-1
- Added check for syncing with ATP & MDDB and publishing to local metric store.
  https://savannah.cern.ch/bugs/index.php?57382
* Mon Oct 26 2009 Emir <eimamagi@srce.hr> - 0.31.1-1
-  Removed ndo2db check. (https://savannah.cern.ch/bugs/?57573)
-  New check org.egee.SendToMetricStore
-  Fixed problem with filtering of VO-dependent services. (http://savannah.cern.ch/bugs/?57287)
-  Added GGUS relate parameters to ConfigGen::Nagios (https://savannah.cern.ch/bugs/?57109):
- GGUS_SERVER_FQDN - if set to valid GGUS server handle_service_change will send notifications
  to GGUS furthremore services which publish notifications will have _GGUS custom var added
  SEND_TO_DASHBOARD - if set handle_service_change will send notifications to dashboard.

* Thu Oct 15 2009 Emir <eimamagi@srce.hr> - 0.30.1-2
- Added ATP SiteInfo and SiteSet modules.
- Added new ATP link which filters site services.
- Updated MDDB module with new JSON feed. Initial commit.
- Added parameters to MDDB module:
  - PROFILE => profile1[,profile2]...
  - VO => vo
- Added LOCAL_METRIC_STORE parameter to ConfigGen::Nagios.
- Set SSL variables locally only.
- Invoke ATP prior to others to get site BDII.
- Added Production and Certification status to ATP.
- Removed ROC as mandatory parameter for both GOCDB and ATP modules. If undefined, module will get all sites.
- Added new default MDDB_URL.
- Added INCLUDE_EMPTY_HOSTS to ConfigGen for excluding hosts without services.
- ConfigGen generates parent only if site has hosts.
- Added new METRIC_STORE_* variables to ConfigGen:
  - METRIC_STORE_DB_USER
  - METRIC_STORE_URI
  - METRIC_STORE_PWD

* Thu Oct 15 2009 Emir <eimamagi@srce.hr> - 0.30.1-1
- ATP and MDDB changes.
* Tue Sep 8 2009 Emir <eimamagi@srce.hr> - 0.29.1-1
- Implemented NCG configuration per site (https://savannah.cern.ch/bugs/index.php?47515).
- Moved invocation of File modules to the end. This will enable finer modifications of config
  (e.g. modifying or removing of data gathered from other modules).
- Implemented REMOVE_SITE in NCG::SiteSet::File for removing sites from the list.
- Added configuration example to config/ncg.multisite.conf.
- Added two File options to SiteInfo:
  - REMOVE_SERVICE - removes service from all hosts
  - REMOVE_HOST_SERVICE - removes service from defined host
- Moved adding/removing hosts from LocalRules/File.pm to SiteInfo/File.pm.
- Added suffix ADD_ to rules for adding hosts and sites:
  SITE, SITE_BDII, HOST_SERVICE, HOST_SERVICE_VO. Old format is still supported.
- Added removing metrics via File module:
  - REMOVE_HOST_SERVICE_METRIC: remove metric for defined host and service
  - REMOVE_SERVICE_METRIC: remove metric for defined service from all hosts
  - REMOVE_HOST_METRIC: remove metric for defined host
  - REMOVE_METRIC: remove metric from all hosts

* Tue Sep 8 2009 Emir <eimamagi@srce.hr> - 0.28.1-1
- Removed MetricSet grouping completely. Mapping is now: (service, metrics).
- Removed a lot of logic from Active.pm which analyzed metricsets (concrete services).
- Changed description of local metrics in Hash.pm to match new MDDB data model.
- Load BDII address from configuration directly.
- Load BDII address from SiteInfo::GOCDB and SiteInfo::SAM.
- Removed LocalMetricSet modules. Updated example config files.

* Tue Aug 25 2009 Emir <eimamagi@srce.hr> - 0.25.1-1
- Correction to check_bdii_entries arguments - bug.

* Tue Aug 25 2009 Emir <eimamagi@srce.hr> - 0.23.1-1
- All org.bdii checks performed with check_bdii_entries.
  Obsolete probes not used anymore (_published, _freshness).
- Added creating CACHE_FILE if it doesn't exist.
  Added changing ownership of the file to NAGIOS_USER.

* Thu Aug 6 2009 Emir <eimamagi@srce.hr> - 0.22.1-1
- Added BDII checks for site profile on CE and Classic SE.
- Added definition of org.gstat.CE and org.gstat.SE validation checks.

* Fri Jul 24 2009 Steve <steve.traylen@cern.ch> - 0.21.1-1
- Remove --mb-destination from CE-JobMonit tests.

* Wed Jul 8 2009 Emir <eimamagi@srce.hr> - 0.20.1-1%{?dist}
- Cosmetic change: renamed field "serviceFlavor" to "serviceFlavour" in order
  to keep naming consistence with ATP DB, new MDDB and Metric Store.
- Use -C instead of -a for process checks. (http://savannah.cern.ch/bugs/?52655)

* Mon Jul 6 2009 Emir <eimamagi@srce.hr> - 0.19.1-1%{?dist}
- Renamed custom var service_type to service_flavor.
- Added ADD_SERVICECONTACT for defining contact for individual service.
- Fixed problem with msg-contact defined for all services.

* Tue Jul 01 2009 Emir <eimamagi@srce.hr> - 0.18.1-1%{?dist}
- Typo again :-)

* Tue Jul 01 2009 Emir <eimamagi@srce.hr> - 0.17.1-1%{?dist}
- Typo

* Tue Jun 30 2009 Emir <eimamagi@srce.hr> - 0.16.1-1%{?dist}
- Added flags:
 SUDO - metric should be executed with sudo
 NOHOSTNAME - metric should be executed without -H $HOSTNAME$
- Added check_nmap_tcp check (org.nmap.*). These checks are equivalent to ENOC Downcollector checks and substitute Nagios native TCP checks.
- Added notification handler (https://savannah.cern.ch/bugs/?52325).
- Added new custom variable "_server" which points to NAGIOS_SERVER.
- Added msg-contact contact which is used for publishing alarms (notifications).
- Contact msg-contact is assigned to all metrics with OBSESS flag.
- All Nagios node checks use standard commands (ncg_check_native, ncg_check_native_local).

* Tue Jun 09 2009 Emir <eimamagi@srce.hr> - 0.15.1-1%{?dist}
- Added support for importing network hierarchy from ENOC. (SiteInfo::ENOC)
  Added verification if host config is already generated.
- Added configuration for ConfigCheck. (see msg-nagios-bridge)
- Added performance processing for NRPE push.
- Implemented additional checks of entries coming from LDAP (https://savannah.cern.ch/bugs/index.php?50232).
- Additional check prior to calling Net::Ping (https://savannah.cern.ch/bugs/index.php?50233)
- Added configuration for NRPE-Push (https://savannah.cern.ch/bugs/?50010).
- Added method for packing NRPE configuration files.

* Wed May 27 2009 Emir <eimamagi@srce.hr> - 0.14.1-1%{?dist}
  Added support for importing results from remote Nagios.
    - added NCG::ConfigPublish::ConfigCache which publishes to SQLite cache
    list of metrics which are published, link back to original nagios is
    provided as action_url
    - added NCG::RemoteMetrics::Nagios which parses available configs in SQLite
    cache and generate passive checks
  Added SERVICE_* servicegroups aggregating all metrics on all hosts.
  Fixed NRPE timeout handling.
  Added support for PROFILE to LocalMetricSets::Hash and LocalMetrics::Hash.
    - four profiles defined: site, roc, project and ngi. Last three are equivalent.
    - difference between site and roc is only in LocalMetricSets::Hash
    (removed all resource BDIIs, MDSs, DPNS and LocalLogger on CE, added SAM CE and WN).
  See ncg.conf.example for examples of using new modules.

* Wed Apr 29 2009 Emir <eimamagi@srce.hr> - 0.12.4-3%{?dist}
  Added MDDB modules


* Tue Apr 28 2009 Emir <eimamagi@srce.hr> - 0.12.3-3%{?dist}
  Fixed bug agaist GOCDB usage.
  https://savannah.cern.ch/bugs/?49714


* Mon Apr 27 2009 Emir <eimamagi@srce.hr> - 0.12.2-3%{?dist}
- Moved back hr.srce.GridProxy-Get under Nagios control.
  https://savannah.cern.ch/bugs/index.php?48853

* Mon Apr 27 2009 Emir <eimamagi@srce.hr> - 0.11.2-3%{?dist}
- Deal with special chars in hostgroups.
  https://savannah.cern.ch/bugs/?49658

* Fri Apr 24 2009 Emir <eimamagi@srce.hr> - 0.11.1-3%{?dist}
- Added freshness check for SAM and DownCollector results.
- Added PNP flag for checks that generate performance data.
- Moved attributes from serviceextinfo to service block.
- Changed GOCDB PI address.
- Generate host even if it doesn't have services
  (covers case of NRPE UI registered as UI in GOCDB).
- Added Country to SiteDB.
- Added Grids to SiteDB.
- Extended NCG::SiteInfo::File with SITE_COUNTRY and SITE_GRID.
- Extended NCG::SiteInfo::GOCDB to retrieve COUNTRY.
- Extended NCG::SiteInfo::LDAP to retrieve COUNTRY from SiteLocation and GRIDS from SiteOtherInfo.
- Extended NCG::SiteInfo::GOCDB to retrieve COUNTRY.
- Extended NCG::SiteSet::LDAP to retrieve COUNTRY from SiteLocation and GRIDS from SiteOtherInfo.
- Added _service_type to service definitions
  https://savannah.cern.ch/bugs/index.php?48610
- Added _grid to service definitions
  https://savannah.cern.ch/bugs/index.php?48921.
- Added COUNTRY and GRIDS hostgroups
  https://savannah.cern.ch/bugs/index.php?48921
  https://savannah.cern.ch/bugs/index.php?48807
- Set local flag in case when native is set
  https://savannah.cern.ch/bugs/index.php?49022.
- https://savannah.cern.ch/bugs/?47540.
- New JSON data structure.
- Added SAM CE probes.
- Commit of Metric Description DB (JSON) based NCG::LocalMetrics and
  NCG::LocalMetricSets modules.
- Remote checks should raise alerts even if *-Gather is in warning state.

* Sun Mar 15 2009 Emir <eimamagi@srce.hr> - 0.10.18-3%{?dist}
- Implemented generating config for a single site in multisite instance
  (<https://savannah.cern.ch/bugs/?46367>)

* Tue Mar 10 2009 Emir <eimamagi@srce.hr> - 0.10.17-3%{?dist}
- Corrected LDAP filters for services.
- Improved VO mapping check.
- Fixed dependency of CADist-Version.
  Fixes: https://savannah.cern.ch/bugs/?47683

* Fri Mar 06 2009 Emir <eimamagi@srce.hr> - 0.10.16-3%{?dist}
- Add %{?dist} to release
- Cleaned up timeouts on internal checks.
  Added 20s to timeout of NRPE checks (https://savannah.cern.ch/bugs/index.php?47522).
  Added 40s to timeout NRPE + check_wlcg checks (https://savannah.cern.ch/bugs/index.php?47522).

* Wed Feb 25 2009 Emir <eimamagi@srce.hr> - 0.10.15-2
- Fixed VO service groups.
- Removed pass-check-dest parameter from org.sam.SRM-All configuration.
  Passive checks are published via standard Python API.
- Added custom variables instead of notes for passing stuff to service_handler:
  _site_name
  _metric_set
  _metric_name
  _service_uri
  _vo
- Corrected VO value passed to service_handler.
- MultiVO checks published without VO suffix.

* Mon Feb 23 2009 Emir <eimamagi@srce.hr> - 0.10.14-1
  Add new vo.template.
  Increased frequency of host checks. Host is down if ping fails for 4 minutes.
  Switched on alerts for SAM-Gather and NPM-Gather.
  Added GridProxy-Get check in case when NRPE_UI is used.
  Implemented <https://savannah.cern.ch/bugs/?47164> Summary: Processes check
  Added PNP4Nagios commands.
  Switched on process performance data for services.
  Added default action_urls for PNP4Nagios.
  Implemented <https://savannah.cern.ch/bugs/?44333> Summary: Support for multple tests by differing VOs.
  Added documentation to NCG::ConfigGen::Nagios.
  Added multiple VO support.
  ClassicSE set only if SRM entry not found.
  Frequency of org.sam.SRM set to 1 hour.


* Tue Feb 17 2009 Steve Traylen <steve.traylen@cern.ch> - 0.10.13-1
- Added disk check on Nagios and NRPE host. - Emir
- Added check of host certificate on Nagios or NRPE host. - Emir
  Fixes: https://savannah.cern.ch/bugs/?46478
- Certificate lifetime check is done by CertLifetime-probe. Emir
- Fixed support for GOCDB-HGSM Aggregator service (SEE) - Christos
- Remove hr.srce.RGMA-CertLifetime temporarily.
- Added metric hr.srce.RGMA-CertLifetime.


* Wed Feb 4 2009 Steve Traylen <steve.traylen@cern.ch> - 0.10.12-1
- Catch errors when SRMs are missing GlueServiceURIs.
- Corrected generating VO servicegroups
  Fixes https://savannah.cern.ch/bugs/?46516

* Wed Jan 28 2009 Steve Traylen <steve.traylen@cern.ch> - 0.10.11-1
- All changes by Emir.
- Addition of GOCDB-HGSM-aggregator - Christos Triantafyllidis <ctria@grid.auth.gr>
  SiteInfo::GHA, SiteSet::GHA and RemoteMetrics::GHA
- Change default WMS TCP port used for host check.
  https://savannah.cern.ch/bugs/?46288
- Addition of GOCDB.pm, i.e GOCDB API intergration.
- Added DB_DIRECTORY option for defining directory of static files in *::File modules.

* Thu Jan 08 2009 Emir Imamagic <eimamagi@srce.hr> - 0.10.10-1
- Added configuration for check which imports scheduled downtimes (ImportGocdbDowntimes).
- Enabled path definition for native metrics (1st phase wlcg->nagios transition).
- Path is defined as one of config variables.
- Two default paths available in static fields in NCG module (NCG_PROBES_PATH_*).
- Native probes now use hostname instead of hostaddress macro.
- Added parameters to metric definition. Parameters are passed directly to probe.
- Parameter can be name or name,value pair.
- NCG::SiteSet::GOCDB supports retrieving data via XML interface.
- Enabled adding passive and parent attributes on probes in NCG::LocalMetrics::Hash.

* Tue Jan 06 2009 James Casey <james.casey@cern.ch> - 0.10.9-2
- renamed org.egee.bdii probeset to org.bdii

* Mon Jan 05 2009 James Casey <james.casey@cern.ch> - 0.10.9-1
- added org.egee.bdii probeset to all BDII variants
- Added HOST_NAME attribute which can be used for LBNodes.
- Corrected message in case of forced check (and possibly expiration in future).
- Added passive local probes for SAM-style complex checks.
- Removed obsess feature on passive probes.
- Added max_check_attempts config var.
* Wed Dec 17 2008 James Casey <james.casey@cern.ch> - 0.10.8-1
- Fix possible values and error message for NAGIOS_ROLE
* Fri Dec 12 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.7-1
- updated commands.template now that handle_service_check takes no parameters
* Fri Dec 12 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.6-1
- Examples of configuration of new modules are added to ncg.multisite.con
  and ncg.conf.example.
- Added module NCG::SiteContacts
  - module gathers user information for AuthZ purposes.
  - in order for this to work character '=' must be removed from
  parameter illegal_object_name_chars in nagios.cfg
- Added GOCDB modules which gather info from GOCDB:
  SiteSet - gets sites from defined federation
  SiteInfo - gets information on nodes on a defined site
  SiteContacts - gets list of users associated with site.
- Aligned service naming with new GOCDB schema.
- Removed obsessiveness from Nagios internal services.
- Removed SITE parameter for send_to_msg command.
- Added NAGIOS_ROLE (site|ROC) variable to NCG::ConfigGen::Nagios.
- Variable NAGIOS_ROLE is passed to OCSP handler.
- SendToMsg is included in multisite configuration.

* Thu Nov 19 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.5-1
- Fixed <https://savannah.cern.ch/bugs/index.php?44291>
  Summary: NCG::SiteInfo::LDAP doesn't recognize BDIIs
- Implemented better error handling of XML::DOM::Parser calls.
- Fixed <https://savannah.cern.ch/bugs/?44290>
  Summary: XML::DOM::Parser parsing error fails NCG
- Fixed <https://savannah.cern.ch/bugs/?44109>
  Summary: hr.srce.CAdist-Version should not run on services that don't authorise us.

* Fri Nov 7 2008 James Casey <james.casey@cern.ch> - 0.10.4-1
- Fix bug #43587: extending 'handle_service_check' OCSP to handle multi-line (details) data from probes
  added --details option to allow to specify a long details string.  Did it this was to be backwards compatible

* Thu Nov 6 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.3-3
- Fixed <https://savannah.cern.ch/bugs/?43659>
  Summary: NCG returns 0 on invalid myproxy host for instance.
- Fixed <https://savannah.cern.ch/bugs/?43682>
  Summary: NCG generates empty hostgroups when remote probes are not present

* Tue Nov 4 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.3-2
- Added noreplace to config files.
  (https://savannah.cern.ch/bugs/?43511)
- Fixed <https://savannah.cern.ch/bugs/?43513>
  Summary: Could not find a service matching host name 'lxvm0340.cern.ch' and description 'SAM-Gather'

* Thu Oct 30 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.3-1
- Added option CHECK_HOSTS to NCG::ConfigGen::Nagios.pm
  if set to false NCG will generate configuration without host checks.
- Added dummy host check (ncg_check_host_dummy) for nodes which we don't know how to check.
- Fixed <https://savannah.cern.ch/bugs/index.php?43301>
  Summary: NCG fails to create a 'host' definition
- Added module NCG::SiteSet::LDAP - gets list of sites for multisite Nagios instance from top level BDII.
  Added configuration example for NCG::SiteSet::LDAP to ncg.multisite.conf.
- Implemented <https://savannah.cern.ch/bugs/?42495>
  Summary: SiteSet should support extracting sites from BDII.
- Fixed <https://savannah.cern.ch/bugs/index.php?42728>
  Summary: Multisite NCG cannot handle LB nodes over multiple sites
- Fixed <https://savannah.cern.ch/bugs/index.php?43333>
  Summary: /etc/nagios/wlcg_resource.cfg is world-readable
- Changed default MYPROXY_NAME to be unique (see <https://savannah.cern.ch/bugs/?42341>).
- Implemented <https://savannah.cern.ch/bugs/?42898>
  Summary: Don't send notifications for all services on MyProxy box to nagios-admin
- Implemented <https://savannah.cern.ch/bugs/?42485>
  Summary: Enable top level BDII usage in NCG::*::LDAP.
- Implemented <https://savannah.cern.ch/bugs/?42334>
  Summary: Be verbose about where we are ldapsearch'ing.
- Fixed <https://savannah.cern.ch/bugs/index.php?42666>
  Summary: NCG leaves alias attribute for nagios hostgroup empty

* Sat Sep 20 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.2-2
- Implemented <https://savannah.cern.ch/bugs/index.php?40737>
  Summary: ncg generating hostgroups.cfg without generating hosts.cfg.
- Fixed <https://savannah.cern.ch/bugs/index.php?42187>
  Summary: The wrong LDAP DN for SRM GlueService* objects is configured in the org.nagios-BDII service probe
- NCG generates only top-level DNs (Mds-Vo-Name=..., O=Grid) for BDII and MDS checks.
- SendToMsq test excluded in case of remote-only and multisite config.
- Fixed <https://savannah.cern.ch/bugs/index.php?42600>
  Summary: LB nodes config broken because of empty notes
- Fixed <https://savannah.cern.ch/bugs/?42602>
  Summary: Error when running ncg.pl from cron
- Fixed <https://savannah.cern.ch/bugs/index.php?42620>
  Summary: Multisite configuration broken

* Sat Sep 20 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.1-2
- Added SendtoMsg template file to RPM.

* Fri Sep 19 2008 James Casey <James.Casey@cern.ch> 0.10.1-1
- Added obsess_over_service parameter to each service.
- Switched off obsessing for services on LB nodes.
- Added SendtoMsg.  Also updated handle_service_check to take extra arguments
- Added encoded notes needed for obsessive handler.
- Enabled notifications for all services.
- Added ENABLE_NOTIFICATIONS option to NCG::ConfigGen::Nagios for enabling alarms.
- Fixed non-existing SE_PORT variable in NCG::ConfigGen::Nagios.

* Tue Sep 16 2008 Emir Imamagic <eimamagi@srce.hr> - 0.10.0-5
- Modules are stored in /usr/lib/perl5/vendor_perl/5.8.5

* Mon Sep 15 2008 Emir Imamagic <eimamagi@srce.hr> 0.10.0-1
- Changed directory hierarchy.
- Moved SiteDB.pm under NCG namespace.
- Implemented CHECK_PING option for disabling ping checks.
- Removed cronjob generation from NCG::ConfigGen::Nagios (moved to nagios-proxy-refresh).
- New default values compliant to RPM directory hierarchy.

* Sun Sep 07 2008 James Casey <James.Casey@cern.ch>> 0.9.12-1
- Added OCSP handle_service_check command definition

* Fri Aug 29 2008 Emir Imamagic <eimamagi@srce.hr> 0.9.12-0
- Added initial support for multisite configuration.
- Fixed problem with empty email in site contact definition.
- NCG generates empty hostgroups for LB nodes when remote-only configuration is used.
  (<https://savannah.cern.ch/bugs/index.php?40840>)
- Added example of static file configuration of site list for multi-site config.

* Tue Jul 22 2008 Emir Imamagic <eimamagi@srce.hr> 0.9.11-2
- Fixed service dependencies configuration.
- Modified cronjob for remote UI so that it doesn't report passive result.
- Cronjob uses probe refresh_proxy in standard way (-u).

* Mon Jun 9 2008 Emir Imamagic <eimamagi@srce.hr> 0.9.11-1
- Added documentation links for native checks to http://nagiosplugins.org.
- Corrected check_dummy configuration to print full output.
- NRPE MyProxy-ProxyLifetime dependencies config fix.

* Fri May 30 2008 Emir Imamagic <eimamagi@srce.hr> 0.9.11-0
- Added remove contact to LocalRules/File.pm. For details see perldoc of NCG/LocalRules/File.pm.
- Gather checks probes (e.g SAM-Gather) are generated only if remote service checks exist.
- Resource file (wlcg_resource.cfg) is generated by NCG.
- NCG generates correct service dependencies when combination PROBE_TYPES=remote,local is used.
  (<https://savannah.cern.ch/bugs/index.php?36338>)
- User variables and their order in resource file have changed
  (<https://savannah.cern.ch/bugs/?35263>)
- NCG::SiteInfo::LDAP supports LFC nodes
  (<https://savannah.cern.ch/bugs/?36340>)
- Added standard Nagios probe check_dummy as active command for passive probes.
  (in case of forced check Nagios will report: No response from XXX-Gather.)
- Removed check if MYPROXY_SERVER is defined in case when PROBE_TYPES doesn't include local.
- Added nagios hostgroup for hosts with internal checks (Nagios, MyProxy and Nrpe).
- Added fix for SAM limitiation of serviceTypes in servicemetrics_per_service_type_critical_for_vo.
 (<https://savannah.cern.ch/bugs/?36947>)
- Added examples & description of new options to default ncg.conf file.
- MyProxy refresh is now done by cron job.
  NCG will generate cron configuration and by default store it to folder /etc/cron.d. Due to this
  change, users are required to restart/reload crond service after running NCG.
  Check GridProxy-Get is now passive check reported by cron job (in case when cron job doesn't report
  result, GridProxy-Get will return unknown).

* Sat Apr 26 2008 James Casey <james.casey@cern.ch> 0.9.10-1
- Fixed VOBOX metric attrs gathering.
- Fixed description of metricset gsissh.
- Removed DOS formatting.
- WMS BDII DN fix.
- Added BDII metricSet to WMS service. Added WMProxy check in LDAP modules (works only with WMS 3.1). Added VO servicegroups for SAM checks and VO-dependent local checks. VO-based host filtering removed, host is generated if there is at least a single service associated with it.

* Fri Mar 14 2008 James Casey <james.casey@cern.ch> 0.9.9-3
- fixed some typo in Local probe db
- Fixed <http://savannah.cern.ch/bugs/?34591> - SAM PI changed case for DETAILED_URL

* Thu Feb 28 2008 James Casey <james.casey@cern.ch> 0.9.9-2
- renamed to grid-monitoring-config-gen to reflect the nagios neutral nature of the approach

* Thu Feb 14 2008 James Casey <james.casey@cern.ch> 0.9.9-1
- rebuilt build systemto handle the new NCG structure

* Tue Oct 09 2007 James Casey <james.casey@cern.ch> 0.9.5-1
- Lots of SRM improvements to deal with SRM2 tests.  Still some nasties to work out, but it's pretty close
- Fixed problem with setting WMProxy port.  Renamed org.glite.LL to org.glite.LocalLogger
- Removed references to aggregate metrics in config files
- Added port checks for services which don't have frequent checks (WMProxy, Locallogger and NetworkServer). Added relevant dependencies.
- Added preliminary support for SRM2 testing.  Tests are only checking ports right now
  for SRM2 endpoints.
- Also added logic to support tcp probes of SRM ports for SRMs, and exclusion of gridftp tests on SE
  endpoints
- Fix bug #28640: hr.srce.WMS-RunJob requires opt/glite/bin/glite-job-submit
  Now ncg.pl is dependant upon the glite version of the UI. Can be specificed
  on the command line.  It will exclude tests which aren't supported on that
  UI version
- Removed aggregate metric checks from Nagios.  These will now just be calculated
  live in the publisher, since it doesn't make sense to keep them in nagios
- Fixed bug #28571: simple-gridftp-probe relies on `pwd`
- Fix Bug #28572 : OSG probe set relies on VDT_VERSION in environment: https://savannah.cern.ch/bugs/?28572
  added separate section to enable OSG probes.  By default, they're disabled.
- Add initial support for OSG Probes
- Remove SE tests if VO not supported
- Added gLite-FTS-WS as node type and some initial checks
- Did some global renaming glite -> gLite
- Made the LFC support either MDS or BDII depending on live check
- Added R-GMA checks on MON box

* Wed Jul 25 2007 James Casey <james.casey@cern.ch> 0.9.4-1
- Fixed [bug #28107] ncg.pl should print out comment header showing some metadata
be aggregated
- Added multiple aggregate metrics calculation. Rewrote aggregate-service-metrics
in perl to avoid dependency problems
- Renamed metric names to org.egee.npm.<servicename>-remote
- Added in link to DownCollector as documentation

* Tue Jul 20 2007 Emir Imamagic <eimamagi@srce.hr> 0.9.3-3
- Added SAM critical tests filtering.

* Tue Jul 17 2007 Emir Imamagic <eimamagi@srce.hr> 0.9.3-2
- Updated NPM name (NMP) and interface.

* Mon Jul 16 2007 James Casey <james.casey@cern.ch> 0.9.3-1
- Added dependencies on nagios_plugins

* Fri Jul 13 2007 Emir Imamagic <eimamagi@srce.hr> 0.9.2-5
- Added remote checks for NMP

* Fri Jul 6 2007 Emir Imamagic <eimamagi@srce.hr> 0.9.2-4
- Modified gridproxy.template according to changes with refresh_proxy

* Fri Jul 6 2007 Emir Imamagic <eimamagi@srce.hr> 0.9.2-3
- Added host-aggregate.template

* Mon Jun 25 2007 James Casey <jamesc@lxadm03.cern.ch> 0.9.1-2
- Removed owner/group arguments from install command

* Thu Jun 21 2007 James Casey <jamesc@lxadm03.cern.ch> 0.9.1-1
- Added Changes files

* Wed Jun 20 2007 James Casey <jamesc@lxadm03.cern.ch>
- Added cadist.template

* Wed Jun 13 2007 James Casey <jamesc@lxadm03.cern.ch> - 0.9-1
- checkpointed 0.9 version

* Mon Jun 11 2007 James Casey <jamesc@lxadm03.cern.ch> - 0.1-1
- Moved share contents into a grid-monitoring directory

* Thu Jun  7 2007 James Casey <jamesc@lxadm02.cern.ch> - Initial
- Initial build.

