codeunit 60301 "Doc. Attachment Provider Pte" implements "Bank Statement Provider Acb"
{
    procedure SelectBankStatements(BankStmtImportSetupAcb: Record "Bank Stmt. Import Setup Acb"; BankStatementHeaderCZB: Record "Bank Statement Header CZB"; var BankStmtRequestListAcb: Codeunit "Bank Stmt. Request List Acb"): Boolean
    begin
        GetBankStatements(BankStmtImportSetupAcb, BankStmtRequestListAcb);
        exit(not BankStmtRequestListAcb.IsEmpty());
    end;

    procedure GetBankStatements(BankStmtImportSetupAcb: Record "Bank Stmt. Import Setup Acb"; var BankStmtRequestListAcb: Codeunit "Bank Stmt. Request List Acb")
    var
        DocumentAttachment: Record "Document Attachment";
        TempNewBankStmtImportRequestAcb: Record "Bank Stmt. Import Request Acb" temporary;
        OutStream: OutStream;
    begin
        GetNewFilesFromWebService(BankStmtImportSetupAcb);

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Bank Stmt. Import Setup Acb");
        DocumentAttachment.SetFilter("No.", BankStmtImportSetupAcb.Code);
        if DocumentAttachment.FindSet() then
            repeat
                if not DocumentAttachment."Document Reference ID".HasValue() then begin
                    Clear(TempNewBankStmtImportRequestAcb);

                    TempNewBankStmtImportRequestAcb.Init();
                    TempNewBankStmtImportRequestAcb.CopyFromBankStmtImportSetup(BankStmtImportSetupAcb);
                    TempNewBankStmtImportRequestAcb."Content Description" :=
                        CopyStr(DocumentAttachment.TableCaption, 1, MaxStrLen(TempNewBankStmtImportRequestAcb."Content Description"));
                    TempNewBankStmtImportRequestAcb.Tag :=
                        CopyStr(DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension", 1, MaxStrLen(TempNewBankStmtImportRequestAcb.Tag));
                    TempNewBankStmtImportRequestAcb.Insert();

                    TempNewBankStmtImportRequestAcb.Content.CreateOutStream(OutStream);
                    DocumentAttachment."Document Reference ID".ExportStream(OutStream);
                    TempNewBankStmtImportRequestAcb.Modify();
                    BankStmtRequestListAcb.Add(TempNewBankStmtImportRequestAcb);

                    TempNewBankStmtImportRequestAcb.Delete();
                end;
            until DocumentAttachment.Next() = 0;
    end;

    procedure GetBankStatementsSilentSupported(): Boolean
    begin
        exit(false);
    end;

    /// <summary>
    /// Bude stahovat nové soubory z webové služby.
    /// </summary>
    /// <remarks>Pouze jako ukázka přidání nového streamu do Document Attachment.</remarks>
    /// <param name="BankStmtImportSetupAcb"></param>
    /// <param name="BankStmtRequestListAcb"></param>
    local procedure GetNewFilesFromWebService(BankStmtImportSetupAcb: Record "Bank Stmt. Import Setup Acb")
    var
        InStream: InStream;
        FileName: Text[250];
    begin
        if UploadFile(BankStmtImportSetupAcb, InStream, FileName) then begin
            SaveStreamToDocumentAttachment(BankStmtImportSetupAcb, FileName, InStream);
            Commit();
        end;
    end;

    local procedure UploadFile(BankStmtImportSetupAcb: Record "Bank Stmt. Import Setup Acb"; var InStream: InStream; var ContentDescription: Text[250]) Selected: Boolean
    var
        DialogTitle: Text;
        FileName: Text;
    begin
        DialogTitle := BankStmtImportSetupAcb.Name;
        if DialogTitle = '' then
            DialogTitle := DialogTitleLbl;

        Selected := UploadIntoStream(DialogTitle, '', FileTypeLbl, FileName, InStream);

        if StrLen(FileName) > MaxStrLen(ContentDescription) then
            ContentDescription := CopyStr(FileManagement.GetFileName(FileName), 1, MaxStrLen(ContentDescription))
        else
            ContentDescription := CopyStr(FileName, 1, MaxStrLen(ContentDescription));
    end;

    local procedure SaveStreamToDocumentAttachment(BankStmtImportSetupAcb: Record "Bank Stmt. Import Setup Acb"; ContentDescription: Text[250]; InStream: InStream)
    var
        DocumentAttachment: Record "Document Attachment";
        RecordRef: RecordRef;
        FileName: Text;
    begin
        RecordRef.GetTable(BankStmtImportSetupAcb);

        Clear(DocumentAttachment);
        DocumentAttachment.InitFieldsFromRecRef(RecordRef);

        FileName := DocumentAttachment.FindUniqueFileName(
            FileManagement.GetFileNameWithoutExtension(ContentDescription),
            FileManagement.GetExtension(ContentDescription));

        DocumentAttachment.SaveAttachmentFromStream(InStream, RecordRef, FileName);
    end;

    #region Document Attachment Handler.
    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Details", 'OnAfterOpenForRecRef', '', false, false)]
    local procedure SetFilterOnAfterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        BankStmtImportSetupAcb: Record "Bank Stmt. Import Setup Acb";
        FieldRef: FieldRef;
        CodeValue: Code[20];
    begin
        if RecRef.Number = Database::"Bank Stmt. Import Setup Acb" then begin
            FieldRef := RecRef.Field(BankStmtImportSetupAcb.FieldNo(Code));
            CodeValue := FieldRef.Value;

            DocumentAttachment.SetRange("Table ID", Database::"Bank Stmt. Import Setup Acb");
            DocumentAttachment.SetRange("No.", CodeValue);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInitFieldsFromRecRef', '', false, false)]
    local procedure InitFieldsOnAfterInitFieldsFromRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        BankStmtImportSetupAcb: Record "Bank Stmt. Import Setup Acb";
        FieldRef: FieldRef;
        CodeValue: Code[20];
    begin
        DocumentAttachment.SetRange("Table ID", RecRef.Number);
        case RecRef.Number of
            Database::"Bank Stmt. Import Setup Acb":
                begin
                    FieldRef := RecRef.Field(BankStmtImportSetupAcb.FieldNo(Code));
                    CodeValue := FieldRef.Value;
                    DocumentAttachment.Validate("No.", CodeValue);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Factbox", 'OnBeforeDrillDown', '', false, false)]
    local procedure GetTableOnBeforeDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        BankStmtImportSetupAcb: Record "Bank Stmt. Import Setup Acb";
    begin
        case DocumentAttachment."Table ID" of
            Database::"Bank Stmt. Import Setup Acb":
                begin
                    RecRef.Open(Database::"Bank Stmt. Import Setup Acb");
                    if BankStmtImportSetupAcb.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(BankStmtImportSetupAcb);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Stmt. Import Setup Acb", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteBankStatementHeaderCZB(var Rec: Record "Bank Stmt. Import Setup Acb")
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec.IsEmpty() then
            exit;

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Bank Stmt. Import Setup Acb");
        DocumentAttachment.SetRange("No.", Rec.Code);
        DocumentAttachment.DeleteAll();
    end;
    #endregion

    var
        FileManagement: Codeunit "File Management";
        DialogTitleLbl: Label 'Import Bank Statement';
        FileTypeLbl: Label 'All Files (*.*)|*.*', Locked = true;
}
