package;

import ArgumentParser.ArgumentParser;
import HxFetch;

class Main {
	static function main() {
		ArgumentParser.register();
		HxFetch.print_fetch("archlinux");
	}
}
