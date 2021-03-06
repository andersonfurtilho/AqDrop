unit AqDrop.Core.Generics.Releaser.Impl;

interface

uses
  System.TypInfo,
  AqDrop.Core.Generics.Releaser;

type
  TAqGenericReleaserImplementation = class(TAqGenericReleaser)
  strict protected
    function DoTryToRelease(const pType: PTypeInfo; const pData: Pointer): Boolean; override;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  AqDrop.Core.Exceptions;

{ TAqGenericReleaserImplementation }

function TAqGenericReleaserImplementation.DoTryToRelease(const pType: PTypeInfo; const pData: Pointer): Boolean;
begin
  Result := pType^.Kind = TTypeKind.tkClass;

  if Result then
  begin
    try
      PObject(pData)^.Free;
    except
      on E: Exception do
      begin
        E.RaiseOuterException(
          EAqInternal.CreateFmt('It wasn''t possible to release a value of type %s.', [GetTypeName(pType)]));
      end;
    end;
  end;
end;

initialization
  TAqGenericReleaser.SetImplementation(TAqGenericReleaserImplementation.Create);

end.
