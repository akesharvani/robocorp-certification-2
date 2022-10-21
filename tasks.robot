*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.Tables
Library           Dialogs
Library           RPA.PDF
Library           RPA.Robocloud.Secrets
Library           RPA.core.notebook
Library           RPA.Archive


*** Keywords ***
Open the robot order website
  ${website}=   Get Secret  websitedata
  Open Available Browser   ${website}[url]
  Maximize Browser Window

*** Keywords ***
Download Csv File
  ${csv_url}=  Get Value From User   Please enter the csv url   https://robotsparebinindustries.com/orders.csv
  Download  ${csv_url}   orders.csv

*** Keywords ***
Fill The Order For First Bot
  [Arguments]   ${order_file}
   Select From List By Value     id:head  ${order_file}[Head]
   Click Element  id-body-${order_file}[Body]
   Wait Until Element Is Enabled  xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input  
   Input Text  xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input  ${order_file}[Legs]
   Wait Until Element Is Enabled    id:address
   Input Text     id:address    ${order_file}[Address]
   Wait Until Element Is Enabled    id:preview
   Click Button    id:preview
   Sleep    3 seconds
   Click Button  id:order
   Sleep  3

*** Keywords ***
Close And Start Browser Prior to Another Transaction
  Close Browser
  Open the robot order website
  Continue For Loop

*** Keywords ***
Checking Receipt Data Processed or Not
  FOR    ${i}    IN RANGE    ${100}
    ${alert}=  Is Element Visible    //div[@class="alert alert-danger"] 
     Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
     Exit For Loop If  '${alert}'=='False'
  END
  
   Run Keyword If  '${alert}'=='True'  Close and start Browser prior to another transaction 


*** Keywords ***
Processing Receipts in final
  [Arguments]  ${order_file}
  Sleep  2 Seconds
  Screenshot  id:order-completion  ${CURDIR}${/}robots${/}${order_file}[Order number].png
  Wait Until Element Is Visible    id:order-completion
  ${reciept_data}=    Get Element Attribute    id:order-completion    outerHTML
  Html To Pdf    ${reciept_data}    ${CURDIR}${/}output${/}${order_file}[Order number].pdf
  Click Button  id:order-another
  Click Button   OK


*** Keywords ***
Fill the Form
  Click Button    OK
  ${orders_file}=  Read table from CSV    orders.csv  header=True
  FOR    ${order_file}    IN    @{orders_file}
    Fill The Order For First Bot    ${order_file}
    Checking Receipt Data Processed or Not
    Processing Receipts in final  ${order_file}
  END

*** Keywords ***
Zip File
  Archive Folder With Zip  ${CURDIR}${/}output  reciepts.zip  recursive=True  include=*.pdf  exclude=/.*


*** Tasks ***
Minimal task
    Open the robot order website
    Download Csv File
    Fill The Form
    Zip File
    Log  Done.






