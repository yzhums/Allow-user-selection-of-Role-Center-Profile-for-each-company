table 50100 ZYUsersRoles
{
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; UserID; Code[20])
        {
            Caption = 'User ID';
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            DataClassification = CustomerContent;
        }
        field(2; CompanyName; Text[25])
        {
            Caption = 'Company Name';
            TableRelation = Company.Name;
            DataClassification = CustomerContent;
        }
        field(3; ProfileID; Code[30])
        {
            Caption = 'Profile ID';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                UserPersonalization: Record "User Personalization";
                TempAllProfile: Record "All Profile" temporary;
            begin
                PopulateProfiles(TempAllProfile);
                if Page.RunModal(Page::Roles, TempAllProfile) = Action::LookupOK then begin
                    ProfileID := TempAllProfile."Profile ID";
                end;
            end;
        }
    }

    keys
    {
        key(PK; UserID, CompanyName)
        {
            Clustered = true;
        }
    }

    var
        DescriptionFilterTxt: Label 'Navigation menu only.';
        UserCreatedAppNameTxt: Label '(User-created)';

    local procedure PopulateProfiles(var TempAllProfile: Record "All Profile" temporary)
    var
        AllProfile: Record "All Profile";
    begin
        TempAllProfile.Reset();
        TempAllProfile.DeleteAll();
        AllProfile.SetRange(Enabled, true);
        AllProfile.SetFilter(Description, '<> %1', DescriptionFilterTxt);
        if AllProfile.FindSet() then
            repeat
                TempAllProfile := AllProfile;
                if IsNullGuid(TempAllProfile."App ID") then
                    TempAllProfile."App Name" := UserCreatedAppNameTxt;
                TempAllProfile.Insert();
            until AllProfile.Next() = 0;
    end;
}

page 50102 "ZY Users Roles"
{
    ApplicationArea = All;
    Caption = 'ZY Users Roles';
    PageType = List;
    SourceTable = ZYUsersRoles;
    UsageCategory = Lists;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(UserID; Rec.UserID)
                {
                    ToolTip = 'Specifies the value of the User ID field.';
                }
                field(CompanyName; Rec.CompanyName)
                {
                    ToolTip = 'Specifies the value of the Company Name field.';
                }
                field(ProfileID; Rec.ProfileID)
                {
                    ToolTip = 'Specifies the value of the Profile ID field.';
                }
            }
        }
    }
}

codeunit 50100 UsersProfilesHandle
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure OnCompanyOpenCompleted();
    var
        ConfPersonMgt: Codeunit "Conf./Personalization Mgt.";
        AllProfile: Record "All Profile";
        ZYUsersRoles: Record ZYUsersRoles;
    begin
        if ZYUsersRoles.Get(UserId, CompanyName) then begin
            AllProfile.Reset();
            AllProfile.SetRange("Profile ID", ZYUsersRoles.ProfileID);
            if AllProfile.FindFirst() then
                ConfPersonMgt.SetCurrentProfile(AllProfile);
        end;
    end;
}

pageextension 50115 UserSettingsExt extends "User Settings"
{
    trigger OnOpenPage()
    begin
        CurrPage.Update();
    end;
}

tableextension 50115 UserSettingsExt extends "User Settings"
{
    trigger OnBeforeModify()
    var
        ZYUsersRoles: Record ZYUsersRoles;
    begin
        if Rec.Company <> xRec.Company then
            if ZYUsersRoles.Get("User ID", Rec.Company) then begin
                Rec."Profile ID" := ZYUsersRoles.ProfileID;
            end;
    end;
}
