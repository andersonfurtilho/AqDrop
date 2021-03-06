unit AqDrop.Core.Generics.Releaser;

interface

uses
  System.TypInfo;

type
  TAqGenericReleaser = class
  strict private
    class var FImplementation: TAqGenericReleaser;
  private
    class procedure ReleaseImplementation;
  strict protected
    function DoTryToRelease(const pType: PTypeInfo; const pData: Pointer): Boolean; virtual; abstract;
  public
    class function TryToRelease<T>(pValue: T): Boolean;

    class procedure SetImplementation(const pImplementation: TAqGenericReleaser);
  end;

implementation

uses
  System.SysUtils,
  AqDrop.Core.Exceptions;

{ TAqGenericReleaser }

class procedure TAqGenericReleaser.ReleaseImplementation;
begin
  FreeAndNil(FImplementation);
end;

class procedure TAqGenericReleaser.SetImplementation(const pImplementation: TAqGenericReleaser);
begin
  ReleaseImplementation;

  FImplementation := pImplementation;
end;

class function TAqGenericReleaser.TryToRelease<T>(pValue: T): Boolean;
begin
  if Assigned(FImplementation) then
  begin
    Result := FImplementation.DoTryToRelease(TypeInfo(T), @pValue);
  end else begin
    raise EAqInternal.Create('No implementation provided for TAqGenericReleaser features.');
  end;
end;

initialization

finalization
  TAqGenericReleaser.ReleaseImplementation;

end.
