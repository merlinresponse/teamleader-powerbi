section teamleader;



BaseUrl = "https://api.focus.teamleader.eu/deals.list?include=lead.customer";

[DataSource.Kind="teamleader", Publish="teamleader.Publish"]
shared teamleader.Contents = (url as text, page as number) =>

    let
            listOfPages = List.Generate( () =>
            [Result= try GetData(1) otherwise null, Page = 1],
            each [Result] <> null,
            each [Result = try GetData([Page]+1) otherwise null, Page=[Page]+1],
            each [Result]),
            
        // concatenate the pages together
        tableOfPages = Table.FromList(listOfPages, Splitter.SplitByNothing(), {"Column1"})
        //#"Column1 uitgevouwen" = Table.ExpandTableColumn(tableOfPages, "Column1", {"Column1"}, {"Column1.Column1"}),
        //#"Column1.Column1 uitgevouwen" = Table.ExpandRecordColumn(#"Column1 uitgevouwen", "Column1.Column1", {"id", "name", "business_type", "vat_number", "national_identification_number", "emails", "telephones", "website", "iban", "bic", "language", "payment_term", "preferred_currency", "invoicing_preferences", "added_at", "updated_at", "web_url", "primary_address", "responsible_user", "tags"}, {"Column1.Column1.id", "Column1.Column1.name", "Column1.Column1.business_type", "Column1.Column1.vat_number", "Column1.Column1.national_identification_number", "Column1.Column1.emails", "Column1.Column1.telephones", "Column1.Column1.website", "Column1.Column1.iban", "Column1.Column1.bic", "Column1.Column1.language", "Column1.Column1.payment_term", "Column1.Column1.preferred_currency", "Column1.Column1.invoicing_preferences", "Column1.Column1.added_at", "Column1.Column1.updated_at", "Column1.Column1.web_url", "Column1.Column1.primary_address", "Column1.Column1.responsible_user", "Column1.Column1.tags"}),
        //#"Rijen gefilterd" = Table.SelectRows(#"Column1.Column1 uitgevouwen", each ([Column1.Column1.id] <> null))
    in
        //#"Rijen gefilterd";
        tableOfPages;

  //GetData(page);

GetData = (page as number) => 
    let
             PostContents = 
        "{
            ""filter"": {    
                ""status"": [""won""]
            },
            ""page"": {
                ""size"": ""50"",
                ""number"": """ & Number.ToText(page) & """
            }
        }",
        source = Web.Contents(BaseUrl, [Content=Text.ToBinary(PostContents)]),
        json = Json.Document(source), 
        data = json[data],    
        included = json[included],
        table = Table.FromList(data, Splitter.SplitByNothing()),
        include_table = Table.FromList(included, Splitter.SplitByNothing()),
        joined_table = Table.Join(table as table, "lead.customer.id", include_table as table, "company.id")  
    in
        table;

//[DataSource.Kind="teamleader"]
//shared teamleader.PagedTable = Value.ReplaceType(teamleader.Pager, type function (url as Uri.Type) as nullable table);


// Data Source Kind description
teamleader = [
Authentication = [
OAuth = [
StartLogin = StartLogin,
FinishLogin = FinishLogin,
Label = "Teamleader OAuth2"
]
],
Label = Extension.LoadString("DataSourceLabel")
];

client_id = "d69d91f2f86209d55570ab14814dc13a"; 
client_secret = "b82f1e807de9fea65d4b1d2275659917";
redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
windowWidth = 1200;
windowHeight = 1000;

StartLogin = (resourceUrl, state, display) =>
let
AuthorizeUrl = "https://focus.teamleader.eu/oauth2/authorize?" & Uri.BuildQueryString([
client_id = client_id,
state = "test",
response_type = "code",
scope="",
redirect_uri = redirect_uri])
in
[
LoginUri = AuthorizeUrl,
CallbackUri = redirect_uri,
WindowHeight = windowHeight,
WindowWidth = windowWidth,
Context = null
];

FinishLogin = (context, callbackUri, state) =>
let
parts = Uri.Parts(callbackUri)[Query],
result = if (Record.HasFields(parts, {"error", "error_description"})) then
error Error.Record(parts[error], parts[error_description], parts)
else
TokenMethod("authorization_code", parts[code])
in
result;

TokenMethod = (grantType, code) =>
let
query = [
client_id = client_id,
client_secret = client_secret,
code = code,
grant_type = "authorization_code",
redirect_uri = redirect_uri],

queryWithCode = if (grantType = "refresh_token") then [ refresh_token = code ] else [code = code],

Response = Web.Contents("https://focus.teamleader.eu/oauth2/access_token", [
Content = Text.ToBinary(Uri.BuildQueryString(query & queryWithCode)),
Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"], ManualStatusHandling = {400}]),


Parts = Json.Document(Response),

Result = if (Record.HasFields(Parts, {"error", "error_description"})) then
error Error.Record(Parts[error], Parts[error_description], Parts)
else
Parts
in
Result;

Refresh = (resourceUrl, refresh_token) => TokenMethod("refresh_token", refresh_token);

teamleader.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = teamleader.Icons,
    SourceTypeImage = teamleader.Icons
];

teamleader.Icons = [
    Icon16 = { Extension.Contents("teamleader16.png"), Extension.Contents("teamleader20.png"), Extension.Contents("teamleader24.png"), Extension.Contents("teamleader32.png") },
    Icon32 = { Extension.Contents("teamleader32.png"), Extension.Contents("teamleader40.png"), Extension.Contents("teamleader48.png"), Extension.Contents("teamleader64.png") }
];


teamleader.Pager = (url as text) => Table.GenerateByPage((url) =>
    let
        current = teamleader.Contents(url)
    in
        current);

Table.GenerateByPage = (getNextPage as function) as table =>
    let        
        listOfPages = List.Generate( () =>
            [Result= try GetData(1) otherwise null, Page = 1],
            each [Result] <> null,
            each [Result = try GetData([Page]+1) otherwise null, Page=[Page]+1],
            each [Result]),

        // concatenate the pages together
        tableOfPages = Table.FromList(listOfPages, Splitter.SplitByNothing(), {"Column1"}),
        firstRow = tableOfPages{0}?
    in
        // if we didn't get back any pages of data, return an empty table
        // otherwise set the table type based on the columns of the first page
        if (firstRow = null) then
            Table.FromRows({})
        else        
            Value.ReplaceType(
                Table.ExpandTableColumn(tableOfPages, "Column1", Table.ColumnNames(firstRow[Column1])),
                Value.Type(firstRow[Column1])
            );
