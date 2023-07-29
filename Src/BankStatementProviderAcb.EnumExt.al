enumextension 60301 "Bank Statement Provider AcbPte" extends "Bank Statement Provider Acb"
{
    value(60301; "Document Attachment Pte")
    {
        Caption = 'Document Attachment';
        Implementation = "Bank Statement Provider Acb" = "Doc. Attachment Provider Pte";
    }
}
