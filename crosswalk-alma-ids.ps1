# example.csv file takes the form of:

# OLDID,NEWID
# 111111111,999999999


$UserBarcodes = Import-Csv "example.csv"
$url_base = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/"
$url_params = "?send_pin_number_letter=false&apikey="
$apiKey = "secret api key"



#For Each User ID in the list of User IDs

foreach ($ID in $UserBarcodes) {
	


#Run Update User Details API to Fetch User XML

$xml = ''


$putUrl = $url_base + $ID.OLDID + $url_params + $apiKey
[xml]$xml = (New-Object System.Net.WebClient).DownloadString("$putUrl")


If ($xml.user.primary_id -eq $ID.OLDID ) {
	
	#Select and update the primary id_type

	$xml.user.primary_id = $ID.NEWID
	
		
[xml]$Response = try {Invoke-WebRequest -Uri $putUrl -Method PUT -Body $xml -ContentType "application/xml"} catch {$_.ErrorDetails.Message}



	#Open user record again to preserve old ID as additional identifier
	
	$putUrl2 = $url_base + $ID.NEWID + $url_params + $apiKey
	
	[xml]$xml = (New-Object System.Net.WebClient).DownloadString("$putUrl2")

	$node = $xml.user.user_identifiers
		
	$node.ParentNode.RemoveChild($node)
		
	#create new IDs node
		
	$newbarcode = $xml.CreateElement("user_identifiers")
		
	#add xml to new ID node
		
				
	$newbarcode.InnerXML = "<user_identifier segment_type='Internal'><id_type desc='Barcode'>BARCODE</id_type><value>" + $ID.OLDID + "0</value><status>ACTIVE</status></user_identifier><user_identifier segment_type='Internal'><id_type desc='Institution ID'>INST_ID</id_type><value>" + $ID.OLDID + "</value><status>ACTIVE</status></user_identifier>"
				
	$xml.user.AppendChild($newbarcode) 

	#PUT the user XML back into Alma with the new ID
	

[xml]$Response = try {Invoke-WebRequest -Uri $putUrl2 -Method PUT -Body $xml -ContentType "application/xml"} catch {$_.ErrorDetails.Message}

$_.ErrorDetails.Message | Out-File debug.txt -Append


#Display old and new ID

Write-Host $ID.SID
Write-Host $ID.EMPLID

	}

}


  