package;

import ArgumentParser.ArgumentParser;
import Console;

class Main {
	static function main() {
		ArgumentParser.register();
		HxFetch.print_fetch("archlinux");
	}
}
