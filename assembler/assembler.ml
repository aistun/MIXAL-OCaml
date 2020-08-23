# 1 "assembler.mll"
 
  open Format

  module StringSet = Set.Make(String)
  module StringMap = Map.Make(String)

  type tokens =
    | Tident of string
    | TassKeyword of string
    | TmixKeyword of string
    | Tsymbol of string
    | Tconst of int
    | Talf of string
    | Teof

  type instrpos = INSTR | ADDR | INDEX | FSPEC | END

  type state = {
      mutable instrpos   : instrpos;
      mutable lastnb     : int option;
      mutable lastbinop  : string option;
      mutable bindings   : int StringMap.t;
      mutable loccounter : int;
      mutable lastassinstr  : string option;
      mutable lastsymdef : string option
  }

  let ass_keywords = StringSet.of_list ["equ"; "orig"; "con"; "alf"; "end"]
  let mix_keywords = StringSet.of_list [
      "nop";
      "add"; "sub"; "mul"; "div";
      "num"; "char"; "hlt";
      "sla"; "sra"; "slax"; "srax"; "slc"; "src";
      "move";
      "lda"; "ld1"; "ld2"; "ld3"; "ld4"; "ld5"; "ld6"; "ldx";
      "ldan"; "ld1n"; "ld2n"; "ld3n"; "ld4n"; "ld5n"; "ld6n"; "ldxn";
      "sta"; "st1"; "st2"; "st3"; "st4"; "st5"; "st6"; "stx"; "stj"; "stz";
      "jbus"; "ioc"; "in"; "out"; "jred";
      "jmp"; "jsj"; "jov"; "jnov"; "jl"; "je"; "jg"; "jge"; "jne"; "jle";
      "jan"; "jaz"; "jap"; "jann"; "janz"; "janp";
      "j1n"; "j1z"; "j1p"; "j1nn"; "j1nz"; "j1np";
      "j2n"; "j2z"; "j2p"; "j2nn"; "j2nz"; "j2np";
      "j3n"; "j3z"; "j3p"; "j3nn"; "j3nz"; "j3np";
      "j4n"; "j4z"; "j4p"; "j4nn"; "j4nz"; "j4np";
      "j5n"; "j5z"; "j5p"; "j5nn"; "j5nz"; "j5np";
      "j6n"; "j6z"; "j6p"; "j6nn"; "j6nz"; "j6np";
      "jxn"; "jxz"; "jxp"; "jxnn"; "jxnz"; "jxnp";
      "inca"; "deca"; "enta"; "enna";
      "inc1"; "dec1"; "ent1"; "enn1";
      "inc2"; "dec2"; "ent2"; "enn2";
      "inc3"; "dec3"; "ent3"; "enn3";
      "inc4"; "dec4"; "ent4"; "enn4";
      "inc5"; "dec5"; "ent5"; "enn5";
      "inc6"; "dec6"; "ent6"; "enn6";
      "incx"; "decx"; "entx"; "ennx";
      "cmpa"; "cmp1"; "cmp2"; "cmp3"; "cmp4"; "cmp5"; "cmp6"; "cmpx"
    ]

  let filename = Sys.argv.(1)

  let pp f = function
    | Tident s      -> printf "IDENT(%s)" s
    | TassKeyword s -> printf "ASS(%s)" s
    | TmixKeyword s -> printf "MIX(%s)" s
    | Tsymbol s -> printf "SYM(%s)" s
    | Tconst n -> printf "CONST(%d)" n
    | Talf s   -> printf "ALF(%s)" s
    | Teof     -> ()

  let print_token = printf "%a " pp

  let rec base f b n =
    if n < b then f n
    else begin
      f (n / b);
      base f b (n mod b)
    end

  let change_instrpos state pos =
    begin match state.lastnb with
    | None -> ()
    | Some nb -> printf "--> %d" nb
    end;
    state.instrpos  <- pos;
    state.lastnb    <- None;
    state.lastbinop <- None

  let reset_instr state =
    begin match state.lastassinstr, state.lastsymdef with
      | Some "equ", Some sym ->
        begin match state.lastnb with
          | None -> failwith "Valeur de l'équivalence non définie."
          | Some nb -> state.bindings <- StringMap.add sym nb state.bindings
        end
      | Some "equ", None ->
          failwith "Impossible de définir une équivalence à un symbole sans nom."
      | None, None
      | Some _, None -> ()
      | None, Some sym
      | Some _, Some sym ->
          state.bindings <- StringMap.add sym state.loccounter state.bindings
    end;
    change_instrpos state INSTR;
    state.lastassinstr <- None;
    state.lastsymdef <- None

  let compute op nb1 nb2 =
    match op with
    | "+" -> nb1 + nb2
    | "-" -> nb1 - nb2
    | "*" -> nb1 * nb2
    | "/" -> nb1 / nb2
    | "//" -> (nb1 * Word.word_max) / nb2
    | ":" -> ((nb1 * 8) mod Word.word_max) + nb2
    | _ -> failwith (op ^ " n'est pas un opérateur binaire.")

  let computation_step state nb =
    match state.lastbinop, state.lastnb with
    (* constante sans opérateurs *)
    | None, _ -> state.lastnb <- Some nb
    (* opérateurs unaires *)
    | Some "+", None ->
      state.lastnb <- Some(nb);
      state.lastbinop <- None
    | Some "-", None ->
      state.lastnb <- Some (- nb);
      state.lastbinop <- None;
    | Some op, None -> failwith (op ^ " n'est pas un opérateur unaire.")
    (* opérateurs binaires *)
    | Some op, Some nb' ->
      state.lastnb <- Some (compute op nb' nb);
      state.lastbinop <- None


# 137 "assembler.ml"
let __ocaml_lex_tables = {
  Lexing.lex_base =
   "\000\000\254\255\001\000\003\000\005\000\008\000\247\255\248\255\
    \083\000\217\000\036\001\111\001\252\255\007\000\011\000\197\000\
    \006\000\255\255\014\000\186\001\021\002\019\000\096\002\187\002\
    ";
  Lexing.lex_backtrk =
   "\255\255\255\255\000\000\001\000\255\255\255\255\255\255\255\255\
    \006\000\005\000\006\000\006\000\255\255\003\000\002\000\001\000\
    \255\255\255\255\001\000\006\000\006\000\004\000\006\000\006\000\
    ";
  Lexing.lex_default =
   "\001\000\000\000\002\000\255\255\255\255\007\000\000\000\000\000\
    \255\255\255\255\255\255\255\255\000\000\255\255\255\255\255\255\
    \016\000\000\000\255\255\255\255\255\255\021\000\255\255\255\255\
    ";
  Lexing.lex_trans =
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\003\000\003\000\255\255\004\000\004\000\004\000\004\000\
    \017\000\014\000\015\000\000\000\014\000\018\000\000\000\018\000\
    \018\000\000\000\000\000\000\000\000\000\255\255\000\000\000\000\
    \003\000\000\000\000\000\004\000\000\000\004\000\000\000\000\000\
    \014\000\000\000\002\000\014\000\000\000\002\000\018\000\002\000\
    \012\000\012\000\012\000\012\000\012\000\012\000\012\000\013\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\012\000\000\000\000\000\012\000\000\000\000\000\
    \000\000\010\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\011\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\015\000\015\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\015\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\016\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \255\255\255\255\000\000\000\000\000\000\000\000\255\255\000\000\
    \006\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\255\255\000\000\000\000\000\000\000\000\
    \000\000\000\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \022\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\019\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\008\000\008\000\008\000\008\000\008\000\
    \020\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\021\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\008\000\008\000\008\000\008\000\008\000\023\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\021\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000";
  Lexing.lex_check =
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\002\000\003\000\003\000\004\000\004\000\
    \016\000\005\000\005\000\255\255\014\000\014\000\255\255\018\000\
    \018\000\255\255\255\255\255\255\255\255\021\000\255\255\255\255\
    \000\000\255\255\255\255\003\000\255\255\004\000\255\255\255\255\
    \005\000\255\255\000\000\014\000\255\255\003\000\018\000\004\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\013\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\255\255\255\255\005\000\255\255\255\255\
    \255\255\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\015\000\015\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\015\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\015\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\002\000\255\255\255\255\255\255\255\255\016\000\255\255\
    \005\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\021\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\010\000\010\000\010\000\010\000\
    \010\000\010\000\010\000\010\000\010\000\010\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\010\000\010\000\010\000\
    \010\000\010\000\010\000\010\000\010\000\010\000\010\000\010\000\
    \010\000\010\000\010\000\010\000\010\000\010\000\010\000\010\000\
    \010\000\010\000\010\000\010\000\010\000\010\000\010\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\010\000\010\000\010\000\
    \010\000\010\000\010\000\010\000\010\000\010\000\010\000\010\000\
    \010\000\010\000\010\000\010\000\010\000\010\000\010\000\010\000\
    \010\000\010\000\010\000\010\000\010\000\010\000\010\000\011\000\
    \011\000\011\000\011\000\011\000\011\000\011\000\011\000\011\000\
    \011\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \011\000\011\000\011\000\011\000\011\000\011\000\011\000\011\000\
    \011\000\011\000\011\000\011\000\011\000\011\000\011\000\011\000\
    \011\000\011\000\011\000\011\000\011\000\011\000\011\000\011\000\
    \011\000\011\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \011\000\011\000\011\000\011\000\011\000\011\000\011\000\011\000\
    \011\000\011\000\011\000\011\000\011\000\011\000\011\000\011\000\
    \011\000\011\000\011\000\011\000\011\000\011\000\011\000\011\000\
    \011\000\011\000\019\000\019\000\019\000\019\000\019\000\019\000\
    \019\000\019\000\019\000\019\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\019\000\019\000\019\000\019\000\019\000\
    \019\000\019\000\019\000\019\000\019\000\019\000\019\000\019\000\
    \019\000\019\000\019\000\019\000\019\000\019\000\019\000\019\000\
    \019\000\019\000\019\000\019\000\019\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\019\000\019\000\019\000\019\000\019\000\
    \019\000\019\000\019\000\019\000\019\000\019\000\019\000\019\000\
    \019\000\019\000\019\000\019\000\019\000\019\000\019\000\019\000\
    \019\000\019\000\019\000\019\000\019\000\020\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \020\000\020\000\020\000\020\000\020\000\020\000\020\000\020\000\
    \022\000\022\000\022\000\022\000\022\000\022\000\022\000\022\000\
    \022\000\022\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\022\000\022\000\022\000\022\000\022\000\022\000\022\000\
    \022\000\022\000\022\000\022\000\022\000\022\000\022\000\022\000\
    \022\000\022\000\022\000\022\000\022\000\022\000\022\000\022\000\
    \022\000\022\000\022\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\022\000\022\000\022\000\022\000\022\000\022\000\022\000\
    \022\000\022\000\022\000\022\000\022\000\022\000\022\000\022\000\
    \022\000\022\000\022\000\022\000\022\000\022\000\022\000\022\000\
    \022\000\022\000\022\000\023\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\023\000\023\000\
    \023\000\023\000\023\000\023\000\023\000\023\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255";
  Lexing.lex_base_code =
   "";
  Lexing.lex_backtrk_code =
   "";
  Lexing.lex_default_code =
   "";
  Lexing.lex_trans_code =
   "";
  Lexing.lex_check_code =
   "";
  Lexing.lex_code =
   "";
}

let rec assemble state lexbuf =
   __ocaml_lex_assemble_rec state lexbuf 0
and __ocaml_lex_assemble_rec state lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 143 "assembler.mll"
                              ( assemble_rec state Word.empty lexbuf )
# 417 "assembler.ml"

  | 1 ->
# 144 "assembler.mll"
      ( assemble_rec state Word.empty lexbuf )
# 422 "assembler.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_assemble_rec state lexbuf __ocaml_lex_state

and assemble_rec state word lexbuf =
   __ocaml_lex_assemble_rec_rec state word lexbuf 5
and __ocaml_lex_assemble_rec_rec state word lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 146 "assembler.mll"
                                        (
      reset_instr state;
      assemble_rec state Word.empty lexbuf
    )
# 437 "assembler.ml"

  | 1 ->
# 150 "assembler.mll"
                                   (
      reset_instr state;
      printf "\n";
      assemble_rec state Word.empty lexbuf
    )
# 446 "assembler.ml"

  | 2 ->
# 155 "assembler.mll"
                 (
      (* tous les espaces blancs ne contenant pas de retour à la ligne *)
      assemble_rec state word lexbuf
    )
# 454 "assembler.ml"

  | 3 ->
let
# 159 "assembler.mll"
               s
# 460 "assembler.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 159 "assembler.mll"
                 (
      print_token (Tsymbol s);
      match s with
      | "+" | "-" | "*" | "/" | "//" | ":" ->
        state.lastbinop <- Some s; assemble_rec state word lexbuf
      | "," ->
        change_instrpos state INDEX; assemble_rec state word lexbuf
      | "(" ->
        change_instrpos state FSPEC; assemble_rec state word lexbuf
      | ")" ->
        change_instrpos state END; assemble_rec state word lexbuf
      | "=" ->
        (* cas à traiter *)
        assemble_rec state word lexbuf
      | _ -> assemble_rec state word lexbuf
    )
# 479 "assembler.ml"

  | 4 ->
let
# 175 "assembler.mll"
                                 s
# 485 "assembler.ml"
= Lexing.sub_lexeme lexbuf (lexbuf.Lexing.lex_start_pos + 4) lexbuf.Lexing.lex_curr_pos in
# 175 "assembler.mll"
                                    (
      print_token (Talf s);
      (* à traiter, pour l'écriture d'une constante alphanumérique *)
      assemble_rec state Word.empty lexbuf
    )
# 493 "assembler.ml"

  | 5 ->
let
# 180 "assembler.mll"
              n
# 499 "assembler.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 180 "assembler.mll"
                  (
      let nb = int_of_string n in
      print_token (Tconst nb);
      computation_step state nb;
      assemble_rec state word lexbuf
    )
# 508 "assembler.ml"

  | 6 ->
let
# 186 "assembler.mll"
                         s
# 514 "assembler.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 186 "assembler.mll"
                           (
      let s' = String.lowercase_ascii s in
      print_token (if StringSet.mem s' ass_keywords then TassKeyword s'
                   else if StringSet.mem s' mix_keywords then TmixKeyword s'
                   else Tident s');
      begin match state.instrpos with
      | INSTR when StringSet.mem s' ass_keywords ->
            if state.lastassinstr = None then state.lastassinstr <- Some s'
            else failwith (s' ^ " est un mot clé, il ne peut pas être un symbole.");
            change_instrpos state ADDR
      | INSTR when StringSet.mem s' mix_keywords ->
            (* remplissage du word avec les codes spécifiques à l'instruction *)
            change_instrpos state ADDR
      | INSTR ->
        printf " (DEF SYMBOLE %s) " s';
        if state.lastsymdef = None then state.lastsymdef <- Some s'
                 else failwith (s' ^ " n'est pas une instruction.")
      | ADDR | INDEX | FSPEC ->
        begin try
          computation_step state (StringMap.find s' state.bindings)
        with Not_found -> failwith (s' ^ " n'est pas un symbole défini.") end
      | END   -> ()
      (* à traiter, pour l'affectation des zones du mot en fonction de
         l'instruction *)
      end;
      assemble_rec state Word.empty lexbuf
    )
# 544 "assembler.ml"

  | 7 ->
# 213 "assembler.mll"
      ( failwith "lexical error" )
# 549 "assembler.ml"

  | 8 ->
# 214 "assembler.mll"
        ( print_token (Teof) )
# 554 "assembler.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_assemble_rec_rec state word lexbuf __ocaml_lex_state

;;

# 215 "assembler.mll"
 
  let state = {
      instrpos   = ADDR;
      lastnb     = None;
      lastbinop  = None;
      bindings   = StringMap.empty;
      loccounter = 0;
      lastassinstr  = None;
      lastsymdef = None
    }
  let () = assemble state (Lexing.from_channel (open_in filename))

# 574 "assembler.ml"
