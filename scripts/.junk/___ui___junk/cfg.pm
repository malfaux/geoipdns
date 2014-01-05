require Exporter;
package veridns::ui::cfg; our @ISA = qw(Exporter);
our @EXPORT = (qw(
	$ui_tabs
	$ui_default_tab
));
use veridns::ui::ctl::geomap;
use veridns::ui::ctl::domain;
use veridns::ui::ctl::template;
use veridns::ui::ctl::mailfw;
$ui_default_tab='z';
$ui_tabs = {
	z=>{
			name=>'Domains',
			defop=>'view',
			ops=>{
				view=>\&dom_view,
				edit=>\&dom_edit,
			},
		},
	g=>{
			name=>'GeoMaps',
			defop=>'view',
			ops=>{
				view=>\&geo_view,
				edit=>\&geo_edit,
			},
		},
	t=>{
			name=>'Templates',
			defop=>'view',
			ops=>{
				view=>\&tmpl_view,
				edit=>\&tmpl_edit,
			},
		},
	m=>{
			name=>'SaveCommit',
			defop=>'do',
			ops=>{'do'=>\&mailfw_do,},
	},
};

1;
