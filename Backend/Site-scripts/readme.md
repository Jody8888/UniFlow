# Site-scripts
This folder contains json scripts for resloving sites.
## Tree
```
```
## Standards
File name contains the subject domain to reslove and formated in json.
File content contains what and whereabouts of the items of intereston the site desired to reslove.
It could go as such:
```json
{
    "Domain":"bjb.xjtu.edu.cn",                     #The subdomain which the file describes.
    "Url":"https://bjb.xjtu.edu.cn/xydt/tzgg.htm",  #Url to the index of th given site.
    "Type":"static" ,                               #Type of site:static (Standard html)/dynamic (Dynamic sites)/api (Known apis)
    "Index":{                                       #The element for page index.
        "Container":"ul",                           #Type of container(ul/li etc...)
        "Class":"listg clearfix",                   #Class signature of the index
        "Entry":{                                   #Entries on the index
            "Container":"li",
            "Class":"",
            "Date_of_Release":{
                "Container":"span",
                "Class":"date-list"                          #Class signature for Date of release
            },
            "link":"a"                              #Link to entry:a(Standard a-href style links)
        }
    },
    "Entry_Content":{                               #Entry content
        "Format":"html",                            #Format of entry(html/php/do/...)
        "Content":{
            "Container":"div",
            "Class":"v_news_content"
        },        
        "Appendix":{
            "Container":"ul",
            "Style":"list-style-type:none;"
        }
    }
}
```