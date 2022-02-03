// Use this file to write queries to test your data connector
let
    result = teamleader.Contents("https://api.focus.teamleader.eu/deals.list?include=lead.customer",1)
in
    result