package;

import HxFetch.Drive;

class Main {
	static function main() {
		var drive:Drive = HxFetch.get_main_drive();
		trace(drive);
	}
}
