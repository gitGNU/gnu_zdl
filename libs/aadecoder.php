<?php

require "$path_usr/libs/php-aaencoder-master/AADecoder.php";
echo AADecoder::decode(file_get_contents($argv[1]));

?>
