<?php
//图片链接的文件名img.txt
$filename = "txt/cover.txt";
if(!file_exists($filename)){
    die('file not found');
}

//从文本获取链接
$pics = [];
$fs = fopen($filename, "r");
while(!feof($fs)){
    $line=trim(fgets($fs));
    if($line!=''){
        array_push($pics, $line);
    }
}

//从数组随机获取链接
$pic = $pics[array_rand($pics)];

//返回指定格式
$type=$_GET['type'];
switch($type){

//JSON返回
case 'json':
    header('Content-type:text/json');
    die(json_encode(['pic'=>$pic]));

default:
    die(header("Location: $pic"));
}
?>
