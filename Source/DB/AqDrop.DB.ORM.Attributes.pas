unit AqDrop.DB.ORM.Attributes;

interface

uses
  AqDrop.Core.Collections.Intf,
  AqDrop.Core.Attributes;

type
  TAqDBTableMappingProperty = (tmpAutoMapFields, tmpAutoMapProperties, tmpInheritPKs);
  TAqDBTableMappingProperties = set of TAqDBTableMappingProperty;

  TAqDBAttribute = class(TAqAttribute);

  AqORMOff = class(TAqDBAttribute);

  AqTable = class(TAqDBAttribute)
  strict private
    FName: string;
    FMappingProperties: TAqDBTableMappingProperties;

    function GetIsNameDefined: Boolean;
  public
    constructor Create(const pName: string = '';
      const pMappingProperties: TAqDBTableMappingProperties = [tmpAutoMapFields]);

    property Name: string read FName;
    property IsNameDefined: Boolean read GetIsNameDefined;
    property MappingProperties: TAqDBTableMappingProperties read FMappingProperties;
  end;

  TAqDBLink = class
  strict private
    FMasterKey: string;
    FForeignKey: string;
  public
    constructor Create(const pMasterKey, pForeignKey: string);

    property MasterKey: string read FMasterKey;
    property ForeignKey: string read FForeignKey;
  end;

  AqSpecialization = class(AqTable)
  strict private
    FLinks: IAqList<TAqDBLink>;

    function GetLinks: IAqReadableList<TAqDBLink>;
  public
    constructor Create(const pName: string; const pMasterKey, pForeignKey: string;
      const pMappingProperties: TAqDBTableMappingProperties = [tmpAutoMapFields, tmpInheritPKs]); overload;
    constructor Create(const pName: string; const pLinks: string;
      const pMappingProperties: TAqDBTableMappingProperties = [tmpAutoMapFields, tmpInheritPKs]); overload;

    property Links: IAqReadableList<TAqDBLink> read GetLinks;
  end;

  TAqDBColumnAttribute = (caPrimaryKey, caAutoIncrement, caNullIfZero, caNullIfEmpty, caDetailKey);
  TAqDBColumnAttributes = set of TAqDBColumnAttribute;

  AqColumn = class(TAqDBAttribute)
  strict private
    FName: string;
    FAttributes: TAqDBColumnAttributes;
    FAlias: string;

    function GetStatusAttribute(const pIndex: TAqDBColumnAttribute): Boolean;
    function GetIsNameDefined: Boolean;
    function GetIsAliasDefined: Boolean;
  strict protected
    function GetAttributes: TAqDBColumnAttributes; virtual;
  public
    constructor Create(const pName: string); overload;
    constructor Create(const pName: string; const pAlias: string); overload;
    constructor Create(const pName: string; const pAttributes: TAqDBColumnAttributes); overload;
    constructor Create(const pName: string; const pAlias: string; const pAttributes: TAqDBColumnAttributes); overload;

    property IsNameDefined: Boolean read GetIsNameDefined;
    property IsAliasDefined: Boolean read GetIsAliasDefined;

    property Name: string read FName;
    property Alias: string read FAlias;
    property Attributes: TAqDBColumnAttributes read GetAttributes;
    property PrimaryKey: Boolean index TAqDBColumnAttribute.caPrimaryKey read GetStatusAttribute;
    property AutoIncrement: Boolean index TAqDBColumnAttribute.caAutoIncrement read GetStatusAttribute;
    property DetailKey: Boolean index TAqDBColumnAttribute.caDetailKey read GetStatusAttribute;
  end;

  AqPrimaryKey = class(AqColumn)
  strict protected
    function GetAttributes: TAqDBColumnAttributes; override;
  end;

  AqDetailKey = class(AqColumn)
  strict protected
    function GetAttributes: TAqDBColumnAttributes; override;
  end;

  AqAutoIncrementColumn = class(AqPrimaryKey)
  strict private
    FGeneratorName: string;

    function GetIsGeneratorDefined: Boolean;
  strict protected
    function GetAttributes: TAqDBColumnAttributes; override;
  public
    constructor Create(const pName: string; const pAlias: string; const pGeneratorName: string); overload;
    constructor Create(const pName: string; const pAttributes: TAqDBColumnAttributes;
      const pGeneratorName: string); overload;
    constructor Create(const pName: string; const pAlias: string;
      const pAttributes: TAqDBColumnAttributes; const pGeneratorName: string); overload;

    property IsGeneratorDefined: Boolean read GetIsGeneratorDefined;
    property GeneratorName: string read FGeneratorName;
  end;

  AqNullIfZeroColumn = class(AqColumn)
  strict protected
    function GetAttributes: TAqDBColumnAttributes; override;
  end;

  AqNullIfEmptyColumn = class(AqColumn)
  strict protected
    function GetAttributes: TAqDBColumnAttributes; override;
  end;

  AqDetail = class(TAqDBAttribute);

implementation

uses
  System.Classes,
  AqDrop.Core.Exceptions,
  AqDrop.Core.Helpers,
  AqDrop.Core.Collections;

{ AqTable }

constructor AqTable.Create(const pName: string; const pMappingProperties: TAqDBTableMappingProperties);
begin
  FName := pName;
  FMappingProperties := pMappingProperties;
end;

function AqTable.GetIsNameDefined: Boolean;
begin
  Result := FName <> '';
end;

{ AqColumn }

constructor AqColumn.Create(const pName, pAlias: string);
begin
  Create(pName, pAlias, []);
end;

constructor AqColumn.Create(const pName: string);
begin
  Create(pName, '', []);
end;

constructor AqColumn.Create(const pName, pAlias: string; const pAttributes: TAqDBColumnAttributes);
begin
  FName := pName;
  FAlias := pAlias;
  FAttributes := pAttributes;
end;

constructor AqColumn.Create(const pName: string; const pAttributes: TAqDBColumnAttributes);
begin
  Create(pName, '', pAttributes);
end;

function AqColumn.GetAttributes: TAqDBColumnAttributes;
begin
  Result := FAttributes;
end;

function AqColumn.GetIsAliasDefined: Boolean;
begin
  Result := not FAlias.IsEmpty;
end;

function AqColumn.GetIsNameDefined: Boolean;
begin
  Result := not FName.IsEmpty;
end;

function AqColumn.GetStatusAttribute(const pIndex: TAqDBColumnAttribute): Boolean;
begin
  Result := pIndex in GetAttributes;
end;

{ AqSpecialization }

constructor AqSpecialization.Create(const pName, pMasterKey, pForeignKey: string;
  const pMappingProperties: TAqDBTableMappingProperties);
begin
  Create(pName, pMasterKey + '=' + pForeignKey, pMappingProperties);
end;

constructor AqSpecialization.Create(const pName, pLinks: string; const pMappingProperties: TAqDBTableMappingProperties);
var
  lLinksBreaker: TStringList;
  lLinkBreaker: TStringList;
  lLink: string;
begin
  inherited Create(pName, pMappingProperties);

  FLinks := TAqList<TAqDBLink>.Create(True);

  lLinksBreaker := TStringList.Create;

  try
    lLinksBreaker.LineBreak := ';';
    lLinksBreaker.Text := pLinks;

    if lLinksBreaker.Count = 0 then
    begin
      raise EAqInternal.Create('Incorrect link list: ' + pLinks);
    end;

    lLinkBreaker := TStringList.Create;

    try
      lLinkBreaker.LineBreak := '=';

      for lLink in lLinksBreaker do
      begin
        lLinkBreaker.Text := lLink;

        if lLinkBreaker.Count <> 2 then
        begin
          raise EAqInternal.Create('Incorrect link: ' + lLink);
        end;

        FLinks.Add(TAqDBLink.Create(lLinkBreaker[0], lLinkBreaker[1]));
      end;
    finally
      lLinkBreaker.Free;
    end;
  finally
    lLinksBreaker.Free;
  end;
end;

function AqSpecialization.GetLinks: IAqReadableList<TAqDBLink>;
begin
  Result := FLinks.GetReadOnlyList;
end;

{ TAqDBLink }

constructor TAqDBLink.Create(const pMasterKey, pForeignKey: string);
begin
  FMasterKey := pMasterKey;
  FForeignKey := pForeignKey;
end;

{ AqPrimaryKey }

function AqPrimaryKey.GetAttributes: TAqDBColumnAttributes;
begin
  Result := inherited + [TAqDBColumnAttribute.caPrimaryKey];
end;

{ AqAutoIncrementColumn }

constructor AqAutoIncrementColumn.Create(const pName, pAlias, pGeneratorName: string);
begin
  Create(pName, pAlias, [], pGeneratorName);
end;

constructor AqAutoIncrementColumn.Create(const pName: string; const pAttributes: TAqDBColumnAttributes;
  const pGeneratorName: string);
begin
  Create(pName, '', pAttributes, pGeneratorName);
end;

constructor AqAutoIncrementColumn.Create(const pName, pAlias: string; const pAttributes: TAqDBColumnAttributes;
  const pGeneratorName: string);
begin
  inherited Create(pName, pAlias, pAttributes);
  FGeneratorName := pGeneratorName;
end;

function AqAutoIncrementColumn.GetAttributes: TAqDBColumnAttributes;
begin
  Result := inherited + [TAqDBColumnAttribute.caAutoIncrement];
end;

function AqAutoIncrementColumn.GetIsGeneratorDefined: Boolean;
begin
  Result := not FGeneratorName.IsEmpty;
end;

{ AqNullIfZeroColumn }

function AqNullIfZeroColumn.GetAttributes: TAqDBColumnAttributes;
begin
  Result := inherited + [TAqDBColumnAttribute.caNullIfZero];
end;

{ AqNullIfEmptyColumn }

function AqNullIfEmptyColumn.GetAttributes: TAqDBColumnAttributes;
begin
  Result := inherited + [TAqDBColumnAttribute.caNullIfEmpty];
end;

{ AqDetailKey }

function AqDetailKey.GetAttributes: TAqDBColumnAttributes;
begin
  Result := inherited + [TAqDBColumnAttribute.caDetailKey];
end;

end.
