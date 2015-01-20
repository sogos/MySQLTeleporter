<?php

$handle = fopen($argv[1], "r");

$dir_path = dirname($argv[1]);

$table_name = $argv[2];
$line_number = 0;
$query_line_number = 0;
$query = array();
$query_found = false;
$keys = array();
$other = array(); 
$auto_increment_columns = array();
if ($handle) {
    while (($line = fgets($handle)) !== false) {
	
	if($query_found) {
		if(preg_match('/^\s+KEY.*(.*)/', $line, $match)) {
			if(preg_match('/^\s+KEY.*\(\`([a-zA-Z0-9_-]{1,})\`\)/', $line, $match)) {
				if(in_array($match[1], $auto_increment_columns)) {
					$query[$query_line_number] = $line;
					$query_line_number++;
				} else {
					$keys[] = 'ADD ' . rtrim(trim($line), ',');
				}
				
			} else {
				$keys[] = 'ADD ' . rtrim(trim($line), ',');
			}
		} else {
			if(preg_match('/^\s+PRIMARY.*/', $line)) {
				$query[$query_line_number] = $line;
			} else {
			if(preg_match('/^\s+\`(.*)\` .* NOT NULL AUTO_INCREMENT.*/', $line, $match)) {
				if($match[1] != "id") {
					$auto_increment_columns[] = $match[1];
				}
			}
			$query[$query_line_number] = $line;	
			}	
			if(preg_match('/.*ENGINE.*/', $line)) {
				$query_found = false;
				$query_size = sizeof($query);
				$query[$query_size - 2] = rtrim(trim($query[$query_size - 2]), ',') . PHP_EOL;
				foreach($query as $query_line) {
					$other[] = $query_line;
				}
			}
			$query_line_number++;
		}
	} elseif(!$query_found && preg_match('/CREATE TABLE.*/', $line, $match)) {
		$query[$query_line_number] = $line;			
		$query_line_number++;
		$query_found = true;
	} else {
		$other[] = $line;
	}
	$line_number++;
    }
} else {
    // error opening the file.
} 


fclose($handle);

$fp = fopen($dir_path . '/create/' . $table_name . '.sql', 'w');
foreach($other as $other_line) {
	fwrite($fp, print_r($other_line, TRUE));
}
fclose($fp);

if(sizeof($keys) == 0) {

	$fpk = fopen($dir_path . '/keys/' . $table_name . '.sql', 'w');
	$query_for_keys = array();
	$query_for_keys[] = "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;";
	$query_for_keys[] = "/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;";
	$query_for_keys[] = "ALTER TABLE " . $table_name;
	$query_for_keys[] = implode(',' . PHP_EOL, $keys) . ";";
	$query_for_keys[] = "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;";
	$query_for_keys[] = "/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;"; 

	foreach($query_for_keys as $query_for_key_line) {

		fwrite($fpk, print_r($query_for_key_line . PHP_EOL , TRUE));
	}
	fclose($fpk);
}
