<?php

//$file = $HTTP_GET['file'];

require "php-aaencoder-master/AADecoder.php";

#echo AADecoder::decode(file_get_contents('encoded.js'));
#echo AADecoder::decode(file_get_contents('../out-videowood'));
#echo AADecoder::decode(file_get_contents('out-encoded'));
#echo AADecoder::decode(file_get_contents('coded-openload'));
#echo AADecoder::decode(file_get_contents('aaencoded.clean'));
echo AADecoder::decode(file_get_contents($argv[1]));

?>
