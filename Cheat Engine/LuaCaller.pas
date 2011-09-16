unit LuaCaller;
{
The luaCaller is a class which contains often defined Events and provides an
interface for gui objects to directly call the lua functions with proper parameters
and results
}

{$mode delphi}

interface

uses
  Classes, Controls, SysUtils, ceguicomponents, forms, lua, lualib, lauxlib,
  comctrls, CEFuncProc;

type
  TLuaCaller=class
    private
      function canRun: boolean;
      procedure pushFunction;
    public
      luaroutine: string;
      luaroutineindex: integer;
      owner: TPersistent;
      procedure NotifyEvent(sender: TObject);
      procedure MouseEvent(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure KeyPressEvent(Sender: TObject; var Key: char);
      procedure LVCheckedItemEvent(Sender: TObject; Item: TListItem); //personal request to have this one added
      procedure CloseEvent(Sender: TObject; var CloseAction: TCloseAction);
      function ActivateEvent(sender: TObject; before, currentstate: boolean): boolean;
      procedure DisassemblerSelectionChangeEvent(sender: TObject; address, address2: ptruint);
      procedure ByteSelectEvent(sender: TObject; address: ptruint; address2: ptruint);
      procedure AddressChangeEvent(sender: TObject; address: ptruint);
      function AutoGuessEvent(address: ptruint; originalVariableType: TVariableType): TVariableType;
      procedure D3DClickEvent(overlayid: integer; x,y: integer);

      constructor create;
      destructor destroy; override;
  end;

procedure CleanupLuaCall(event: TMethod);   //cleans up a luacaller class if it was assigned if it was set

implementation

uses luahandler, MainUnit;

procedure CleanupLuaCall(event: TMethod);
begin
  if (event.code<>nil) and (event.data<>nil) and (TObject(event.data) is TLuaCaller) then
    TLuaCaller(event.data).free;

end;

constructor TLuaCaller.create;
begin
  luaroutineindex:=-1;
end;

destructor TLuaCaller.destroy;
begin
  if luaroutineindex<>-1 then //deref
    luaL_unref(luavm, LUA_REGISTRYINDEX, luaroutineindex);
end;

function TLuaCaller.canRun: boolean;
var baseOwner: TComponent;
begin
  baseOwner:=Tcomponent(owner);
  if baseOwner<>nil then
  begin
    while (not (baseOwner is TCustomForm)) and (baseowner.Owner<>nil) do //as long as the current base is not a form and it still has a owner
      baseOwner:=baseowner.owner;
  end;

  result:=(baseowner=nil) or (not ((baseOwner is TCEform) and (TCEForm(baseowner).designsurface<>nil) and (TCEForm(baseowner).designsurface.active)));
end;

procedure TLuaCaller.pushFunction;
begin
  if luaroutineindex=-1 then //get the index of the given routine
    lua_getfield(LuaVM, LUA_GLOBALSINDEX, pchar(luaroutine))
  else
    lua_rawgeti(Luavm, LUA_REGISTRYINDEX, luaroutineindex)
end;

procedure TLuaCaller.NotifyEvent(sender: TObject);
var oldstack: integer;
begin
  Luacs.Enter;
  try
    oldstack:=lua_gettop(Luavm);

    if canRun then
    begin
      PushFunction;
      lua_pushlightuserdata(Luavm, sender);

      lua_pcall(Luavm, 1,0,0); //procedure(sender)
    end;
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

procedure TLuaCaller.CloseEvent(Sender: TObject; var CloseAction: TCloseAction);
var oldstack: integer;
begin
  Luacs.Enter;
  try
    oldstack:=lua_gettop(Luavm);

    if canRun then
    begin
      PushFunction;
      lua_pushlightuserdata(Luavm, sender);


      if lua_pcall(Luavm, 1,1,0)=0 then //procedure(sender)  lua_pcall returns 0 if success
      begin
        if lua_gettop(Luavm)>0 then
          CloseAction:=TCloseAction(lua_tointeger(LuaVM,-1));
      end
      else
        closeAction:=caHide; //not implemented by the user

      if mainform.mustclose then
        closeaction:=cahide;

    end
    else closeaction:=caHide;
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

function TLuaCaller.ActivateEvent(sender: tobject; before, currentstate: boolean): boolean;
var oldstack: integer;
begin
  result:=true;
  Luacs.Enter;
  try
    oldstack:=lua_gettop(Luavm);

    if canRun then
    begin
      PushFunction;
      lua_pushlightuserdata(Luavm, sender);
      lua_pushboolean(luavm, before);
      lua_pushboolean(luavm, currentstate);


      lua_pcall(Luavm, 3,1,0); //function(sender, before, currentstate):boolean

      if lua_gettop(Luavm)>0 then
        result:=lua_toboolean(LuaVM,-1);

    end;
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

procedure TLuaCaller.DisassemblerSelectionChangeEvent(sender: tobject; address, address2: ptruint);
var oldstack: integer;
begin
  Luacs.Enter;
  try
    oldstack:=lua_gettop(Luavm);

    if canRun then
    begin
      PushFunction;
      lua_pushlightuserdata(Luavm, sender);
      lua_pushinteger(luavm, address);
      lua_pushinteger(luavm, address2);


      lua_pcall(Luavm, 3,0,0); //procedure(sender, address, address2)
    end;
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

procedure TLuaCaller.ByteSelectEvent(sender: TObject; address: ptruint; address2: ptruint);
var oldstack: integer;
begin
  Luacs.Enter;
  try
    oldstack:=lua_gettop(Luavm);

    if canRun then
    begin
      PushFunction;
      lua_pushlightuserdata(Luavm, sender);
      lua_pushinteger(luavm, address);
      lua_pushinteger(luavm, address2);

      lua_pcall(Luavm, 3,0,0); //procedure(sender, address, address2)
    end;
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

procedure TLuaCaller.D3DClickEvent(overlayid: integer; x,y: integer);
var oldstack: integer;
begin
  Luacs.Enter;
  try
    oldstack:=lua_gettop(Luavm);

    if canRun then
    begin
      PushFunction;
      lua_pushinteger(luavm, overlayid);
      lua_pushinteger(luavm, x);
      lua_pushinteger(luavm, y);
      lua_pcall(Luavm, 3,0,0)
    end;
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

procedure TLuaCaller.AddressChangeEvent(sender: TObject; address: ptruint);
var oldstack: integer;
begin
  Luacs.Enter;
  try
    oldstack:=lua_gettop(Luavm);

    if canRun then
    begin
      PushFunction;
      lua_pushlightuserdata(Luavm, sender);
      lua_pushinteger(luavm, address);

      lua_pcall(Luavm, 2,0,0); //procedure(sender, address)
    end;
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;



function TLuaCaller.AutoGuessEvent(address: ptruint; originalVariableType: TVariableType): TVariableType;
var oldstack: integer;
begin
  Luacs.enter;
  try
    oldstack:=lua_gettop(Luavm);

    PushFunction;
    lua_pushinteger(luavm, address);
    lua_pushinteger(luavm, integer(originalVariableType));
    if lua_pcall(LuaVM, 2, 1, 0)=0 then         // lua_pcall returns 0 if success
      result:=TVariableType(lua_tointeger(LuaVM,-1))
    else
      result:=originalVariableType;




  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

procedure TLuaCaller.MouseEvent(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var oldstack: integer;
begin
  Luacs.enter;
  try
    oldstack:=lua_gettop(Luavm);
    pushFunction;
    lua_pushlightuserdata(luavm, sender);
    lua_pushinteger(luavm, integer(Button));
    lua_pushinteger(luavm, x);
    lua_pushinteger(luavm, y);

    lua_pcall(LuaVM, 4, 0, 0);
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

procedure TLuaCaller.KeyPressEvent(Sender: TObject; var Key: char);
var oldstack: integer;
  s: string;
begin
  Luacs.enter;
  try
    oldstack:=lua_gettop(Luavm);
    pushFunction;
    lua_pushlightuserdata(luavm, sender);
    lua_pushstring(luavm, key);
    if lua_pcall(LuaVM, 2, 1, 0)=0 then  //lua_pcall returns 0 if success
    begin
      if lua_isstring(LuaVM, -1) then
      begin
        s:=lua_tostring(LuaVM,-1);
        if length(s)>0 then
          key:=s[1]
        else
          key:=#0; //invalid string
      end
      else
      if lua_isnumber(LuaVM, -1) then
        key:=chr(lua_tointeger(LuaVM, -1))
      else
        key:=#0; //invalid type returned
    end;
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end;
end;

procedure TLuaCaller.LVCheckedItemEvent(Sender: TObject; Item: TListItem);
var oldstack: integer;
begin
  Luacs.enter;
  try
    oldstack:=lua_gettop(Luavm);
    pushFunction;
    lua_pushlightuserdata(luavm, sender);
    lua_pushlightuserdata(luavm, item);
    lua_pcall(LuaVM, 2, 0, 0);
  finally
    lua_settop(Luavm, oldstack);
    luacs.leave;
  end
end;

end.

