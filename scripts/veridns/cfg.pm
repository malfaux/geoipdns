package veridns::cfg;

use base qw(Exporter);
our %EXPORT_TAGS = ( 'cf_' => [ qw(
    $cf_tmpdir
	$cf_ssh_port
	$cf_ssh_priv_key
	$cf_ssh_pub_key
	$cf_userdir
	$cf_admin
	$cf_dns_servers
	$cf_default_loc
	$cf_mname
	$cf_rname
	$cf_geoip_dumpdir 
	$cf_geoip_cc_dumpfile 
	$cf_geoip_cc_dlurl 
	$cf_geoip_cc_srcfile 
	$cf_geoip_cc_storable
	$cf_geoip_cc_in
	$cf_geoip_cc_cdb
	$cf_geoip_asn_dumpfile 
	$cf_geoip_asn_dlurl 
	$cf_geoip_asn_srcfile 
	$cf_geoip_dns_root 
	$cf_geoip_dns_userdir 
	$cf_geoip_umap_in
	$cf_geoip_umap_out
	$cf_countries
	$cf_sql_username
	$cf_sql_password
	$cf_sql_db
	$cf_sql_url
	) ],
	'countries'=>[qw($cf_countries)]
	);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'cf_'} }, @{ $EXPORT_TAGS{'countries'} } );
$cf_rootdir = '/var/db/geoipdns';
if (! -d $cf_rootdir) { die unless mkdir $cf_rootdir; }
$cf_wdir=$cf_rootdir;
$cf_geoip_dumpdir=$cf_rootdir;
$cf_userdir=$cf_rootdir;
$cf_geoip_dns_root = $cf_rootdir;
$cf_geoip_dns_userdir = $cf_userdir;
$cf_tmpdir = $cf_rootdir;
$cf_geoip_cc_dumpfile="$cf_geoip_dumpdir/GeoIpCountryCSV.zip";
$cf_geoip_cc_srcfile = "$cf_geoip_dumpdir/GeoIpCountryWhois.csv";
$cf_geoip_cc_dlurl = 'http://www.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip';
$cf_geoip_asn_dumpfile="$cf_geoip_dumpdir/GeoIPASNum2.zip";
$cf_geoip_asn_srcfile="$cf_geoip_dumpdir/GeoIPASNum2.csv";
$cf_geoip_asn_dlurl="http://www.maxmind.com/download/geoip/database/asnum/GeoIPASNum2.zip";


$cf_ssh_port=2022;
$cf_ssh_priv_key = $cf_rootdir . '/id_rsa';
$cf_ssh_pub_key = $cf_rootdir . '/id_rsa.pub';

$cf_admin = '"root" <root@localhost>';
$cf_dns_servers={
	
};
$cf_default_loc = 'nomatch';
$cf_sql_username='geoipdns';
$cf_sql_password=undef;
$cf_sql_db='geoipdns';
$cf_sql_url="dbi:Pg:dbname=$cf_sql_db";
$cf_mname='hostmaster.geoipdns.org';
$cf_rname = 'ns1.geoipdns.org';


$cf_geoip_umap_in="ipmaps.xml";
$cf_geoip_umap_out="ipmaps.cdb.in";

$cf_geoip_cc_storable="$cf_rootdir/ipmaps.sto";
$cf_geoip_cc_cdb="$cf_rootdir/ipmaps.cdb";
$cf_geoip_cc_in="$cf_rootdir/ipmaps.data.in";

$cf_countries= {
          'GL' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Greenland'
                  },
          'DJ' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Djibouti'
                  },
          'JM' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Jamaica'
                  },
          'AT' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Austria'
                  },
          'PG' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Papua New Guinea'
                  },
          'KI' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Kiribati'
                  },
          'SZ' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Swaziland'
                  },
          'YT' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Mayotte'
                  },
          'BN' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Brunei Darussalam'
                  },
          'CD' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Congo, The Democratic Republic of the'
                  },
          'ZM' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Zambia'
                  },
          'AO' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Angola'
                  },
          'BW' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Botswana'
                  },
          'ZW' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Zimbabwe'
                  },
          'VC' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Saint Vincent and the Grenadines'
                  },
          'PR' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Puerto Rico'
                  },
          'JP' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Japan'
                  },
          'NA' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Namibia'
                  },
          'TJ' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Tajikistan'
                  },
          'LC' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Saint Lucia'
                  },
          'MA' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Morocco'
                  },
          'MT' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Malta'
                  },
          'SV' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'El Salvador'
                  },
          'VU' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Vanuatu'
                  },
          'MN' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Mongolia'
                  },
          'MP' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Northern Mariana Islands'
                  },
          'IT' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Italy'
                  },
          'RE' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Reunion'
                  },
          'WS' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Samoa'
                  },
          'EG' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Egypt'
                  },
          'FR' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'France'
                  },
          'PW' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Palau'
                  },
          'UZ' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Uzbekistan'
                  },
          'LR' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Liberia'
                  },
          'TK' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Tokelau'
                  },
          'RW' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Rwanda'
                  },
          'BE' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Belgium'
                  },
          'TN' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Tunisia'
                  },
          'UM' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'United States Minor Outlying Islands'
                  },
          'EE' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Estonia'
                  },
          'CK' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Cook Islands'
                  },
          'BY' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Belarus'
                  },
          'KR' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Korea'
                  },
          'LS' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Lesotho'
                  },
          'NO' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Norway'
                  },
          'SA' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Saudi Arabia'
                  },
          'ZA' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'South Africa'
                  },
          'PT' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Portugal'
                  },
          'BF' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Burkina Faso'
                  },
          'CA' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Canada'
                  },
          'AM' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Armenia'
                  },
          'CM' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Cameroon'
                  },
          'MG' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Madagascar'
                  },
          'SR' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Suriname'
                  },
          'NP' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Nepal'
                  },
          'BT' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Bhutan'
                  },
          'PL' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Poland'
                  },
          'CF' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Central African Republic'
                  },
          'GA' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Gabon'
                  },
          'TM' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Turkmenistan'
                  },
          'BA' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Bosnia and Herzegovina'
                  },
          'AE' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'United Arab Emirates'
                  },
          'KY' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Cayman Islands'
                  },
          'TH' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Thailand'
                  },
          'LA' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Lao People\'s Democratic Republic'
                  },
          'PH' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Philippines'
                  },
          'NI' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Nicaragua'
                  },
          'GU' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Guam'
                  },
          'NC' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'New Caledonia'
                  },
          'KZ' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Kazakstan'
                  },
          'MM' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Myanmar'
                  },
          'NR' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Nauru'
                  },
          'DM' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Dominica'
                  },
          'NE' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Niger'
                  },
          'EU' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Europe'
                  },
          'AD' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Andorra'
                  },
          'MR' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Mauritania'
                  },
          'TO' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Tonga'
                  },
          'SE' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Sweden'
                  },
          'AZ' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Azerbaijan'
                  },
          'AF' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Afghanistan'
                  },
          'NG' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Nigeria'
                  },
          'BJ' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Benin'
                  },
          'KE' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Kenya'
                  },
          'ME' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Montenegro'
                  },
          'OM' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Oman'
                  },
          'VG' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Virgin Islands,British'
                  },
          'VN' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Vietnam'
                  },
          'DZ' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Algeria'
                  },
          'CI' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Cote D\'Ivoire'
                  },
          'YE' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Yemen'
                  },
          'LK' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Sri Lanka'
                  },
          'ID' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Indonesia'
                  },
          'FM' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Micronesia'
                  },
          'GE' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Georgia'
                  },
          'GM' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Gambia'
                  },
          'LV' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Latvia'
                  },
          'LB' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Lebanon'
                  },
          'RU' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Russian Federation'
                  },
          'FK' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Falkland Islands (Malvinas)'
                  },
          'DE' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Germany'
                  },
          'FI' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Finland'
                  },
          'MV' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Maldives'
                  },
          'LU' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Luxembourg'
                  },
          'VE' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Venezuela'
                  },
          'BH' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Bahrain'
                  },
          'GI' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Gibraltar'
                  },
          'RO' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Romania'
                  },
          'WF' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Wallis and Futuna'
                  },
          'AR' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Argentina'
                  },
          'GP' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Guadeloupe'
                  },
          'IN' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'India'
                  },
          'TV' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Tuvalu'
                  },
          'VI' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Virgin Islands, US'
                  },
          'AW' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Aruba'
                  },
          'FO' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Faroe Islands'
                  },
          'MX' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Mexico'
                  },
          'SN' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Senegal'
                  },
          'BR' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Brazil'
                  },
          'HN' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Honduras'
                  },
          'MC' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Monaco'
                  },
          'IL' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Israel'
                  },
          'SB' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Solomon Islands'
                  },
          'DO' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Dominican Republic'
                  },
          'HU' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Hungary'
                  },
          'NZ' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'New Zealand'
                  },
          'PS' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Palestinian Territory'
                  },
          'UG' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Uganda'
                  },
          'KH' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Cambodia'
                  },
          'GB' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'United Kingdom'
                  },
          'TG' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Togo'
                  },
          'BB' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Barbados'
                  },
          'HT' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Haiti'
                  },
          'DK' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Denmark'
                  },
          'PA' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Panama'
                  },
          'CV' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Cape Verde'
                  },
          'QA' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Qatar'
                  },
          'GD' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Grenada'
                  },
          'GF' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'French Guiana'
                  },
          'MO' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Macau'
                  },
          'KM' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Comoros'
                  },
          'KW' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Kuwait'
                  },
          'HR' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Croatia'
                  },
          'MQ' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Martinique'
                  },
          'TC' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Turks and Caicos Islands'
                  },
          'CZ' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Czech Republic'
                  },
          'ES' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Spain'
                  },
          'MZ' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Mozambique'
                  },
          'BO' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Bolivia'
                  },
          'AU' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Australia'
                  },
          'ST' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Sao Tome and Principe'
                  },
          'AL' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Albania'
                  },
          'IR' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Iran'
                  },
          'CG' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Congo'
                  },
          'MD' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Moldova'
                  },
          'TR' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Turkey'
                  },
          'GW' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Guinea-Bissau'
                  },
          'GN' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Guinea'
                  },
          'BI' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Burundi'
                  },
          'MK' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Macedonia'
                  },
          'GR' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Greece'
                  },
          'AG' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Antigua and Barbuda'
                  },
          'CO' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Colombia'
                  },
          'AP' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Asia/Pacific Region'
                  },
          'SI' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Slovenia'
                  },
          'AI' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Anguilla'
                  },
          'AQ' => {
                    'ccode' => 'AQ',
                    'continent' => 'Antarctica',
                    'name' => 'Antarctica'
                  },
          'AN' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Netherlands Antilles'
                  },
          'JO' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Jordan'
                  },
          'SM' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'San Marino'
                  },
          'UA' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Ukraine'
                  },
          'CU' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Cuba'
                  },
          'CL' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Chile'
                  },
          'KN' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Saint Kitts and Nevis'
                  },
          'ML' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Mali'
                  },
          'ET' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Ethiopia'
                  },
          'SC' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Seychelles'
                  },
          'IS' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Iceland'
                  },
          'MS' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Montserrat'
                  },
          'NL' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Netherlands'
                  },
          'HK' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Hong Kong'
                  },
          'EC' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Ecuador'
                  },
          'A2' => {
                    'ccode' => 'WW',
                    'continent' => 'WW',
                    'name' => 'Satellite Provider'
                  },
          'MY' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Malaysia'
                  },
          'CR' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Costa Rica'
                  },
          'VA' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Holy See (Vatican City State)'
                  },
          'IO' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'British Indian Ocean Territory'
                  },
          'RS' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Serbia'
                  },
          'SD' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Sudan'
                  },
          'CN' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'China'
                  },
          'BG' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Bulgaria'
                  },
          'MH' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Marshall Islands'
                  },
          'UY' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Uruguay'
                  },
          'BS' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Bahamas'
                  },
          'PY' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Paraguay'
                  },
          'MU' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Mauritius'
                  },
          'LI' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Liechtenstein'
                  },
          'CH' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Switzerland'
                  },
          'KG' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Kyrgyzstan'
                  },
          'GH' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Ghana'
                  },
          'NU' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Niue'
                  },
          'PE' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Peru'
                  },
          'US' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'United States'
                  },
          'BZ' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Belize'
                  },
          'SL' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Sierra Leone'
                  },
          'CY' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Cyprus'
                  },
          'FJ' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Fiji'
                  },
          'IE' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Ireland'
                  },
          'TW' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Taiwan'
                  },
          'KP' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Korea, Democratic People\'s Republic of'
                  },
          'PF' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'French Polynesia'
                  },
          'ER' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Eritrea'
                  },
          'IQ' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Iraq'
                  },
          'AS' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'American Samoa'
                  },
          'MW' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Malawi'
                  },
          'TZ' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Tanzania'
                  },
          'LY' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Libyan Arab Jamahiriya'
                  },
          'GT' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Guatemala'
                  },
          'GY' => {
                    'ccode' => 'SA',
                    'continent' => 'South America',
                    'name' => 'Guyana'
                  },
          'BM' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Bermuda'
                  },
          'GQ' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Equatorial Guinea'
                  },
          'PK' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Pakistan'
                  },
          'BV' => {
                    'ccode' => 'AQ',
                    'continent' => 'Antarctica',
                    'name' => 'Bouvet Island'
                  },
          'LT' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Lithuania'
                  },
          'SG' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Singapore'
                  },
          'TT' => {
                    'ccode' => 'NA',
                    'continent' => 'North America',
                    'name' => 'Trinidad and Tobago'
                  },
          'NF' => {
                    'ccode' => 'OC',
                    'continent' => 'Oceania',
                    'name' => 'Norfolk Island'
                  },
          'SO' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Somalia'
                  },
          'TD' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Chad'
                  },
          'SK' => {
                    'ccode' => 'EU',
                    'continent' => 'Europe',
                    'name' => 'Slovakia'
                  },
          'SY' => {
                    'ccode' => 'AS',
                    'continent' => 'Asia',
                    'name' => 'Syrian Arab Republic'
                  },
          'HM' => {
                    'ccode' => 'AQ',
                    'continent' => 'Antarctica',
                    'name' => 'Heard Island and McDonald Islands'
                  },
          'BD' => {
                    'ccode' => 'AF',
                    'continent' => 'Africa',
                    'name' => 'Bangladesh'
                  }
        };

1;

