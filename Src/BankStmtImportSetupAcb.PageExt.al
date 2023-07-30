pageextension 60301 "Bank Stmt. Import Setup AcbPte" extends "Bank Stmt. Import Setup Acb"
{
    layout
    {
        addlast(FactBoxes)
        {
            // TODO: Pouze testovací náhled na přílohy
            part("Attached Documents Pte"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(52057424), "No." = field(Code);
                Visible = Rec."Bank Statement Provider" = Rec."Bank Statement Provider"::"Document Attachment Pte";
                Enabled = Rec."Bank Statement Provider" = Rec."Bank Statement Provider"::"Document Attachment Pte";
            }
        }
    }
}
