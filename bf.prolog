
% let's write a quick brainf.. bf in prolog :)

%% first let's define what constitutes a bf program

command( lt ). % left
command( rt ). % right
command( up ). % up         ( increment )
command( dn ). % down       ( decrement )
command( sl ). % start-loop
command( el ). % end-loop
command( rd ). % read
command( wr ). % write

program( [] )    :- true .
program( [C|R] ) :- command( C ), program( R ).

%% MEMORY
%%
%% in BF, memory is an infinite array of cells, each holding a number
%% there is a "current" cell being pointed at. the BF commands allow
%% us to move the pointer left or right, increment or decrement the
%% value at the location of the current pointer, to read from user
%% input and overwrite the current cell with the given value, or to
%% output the value of the current cell.
%% 
%% to represent this efficiently in prologs datastructures, we're
%% using five components. we have the value of the current cell,
%% a list of leftward cell values ( ordered from us to the left, so
%% in reverse order ), a list of rightward cell values ( ordered
%% normally ), an input list ( simulating the keypresses a user
%% will have given, and then yielding 0 after running out ), and
%% an output list, containing what would have been printed
%% 

% C  - value of the currently pointed to cell
% LL - the list of cells to the left of the current cell
% RR - the list of cells to the right of the current cell
% L  - the left head ( first item ), next in to the left
% R  - the right head ( first item ), next in to the right
% II - the list of pending input to the program
% I  - the head ( first item ) of the input list
% OO - the list of accumulated output from the program
% S  - the resulting sum
% D  - the resulting difference

% [X|XX] - matches a list as the first item, and then the rest of it
%   the same syntax is used to both build and deconstruct lists

memory(II,MM) :- MM = [ 0, [], [], II, [] ].

memory_lt([ C, []    , RR    , II    , OO ] , New) :-             New = [ 0, []    , [C|RR], II, OO     ].
memory_lt([ C, [L|LL], RR    , II    , OO ] , New) :-             New = [ L, LL    , [C|RR], II, OO     ].
memory_rt([ C, LL    , []    , II    , OO ] , New) :-             New = [ 0, [C|LL], []    , II, OO     ].
memory_rt([ C, LL    , [R|RR], II    , OO ] , New) :-             New = [ R, [C|LL], RR    , II, OO     ].
memory_up([ C, LL    , RR    , II    , OO ] , New) :- S is C + 1, New = [ S, LL    , RR    , II, OO     ].
memory_dn([ C, LL    , RR    , II    , OO ] , New) :- D is C - 1, New = [ D, LL    , RR    , II, OO     ].
memory_rd([ _, LL    , RR    , [I|II], OO ] , New) :-             New = [ I, LL    , RR    , II, OO     ].
memory_wr([ C, LL    , RR    , II    , OO ] , New) :-             New = [ C, LL    , RR    , II, [C|OO] ].

%% a helper to extract the output when finished
%% 
memory_out([ _, _, _, _, OO ],Grab) :- Grab = OO.

memory_current_cell_zero([0, _, _, _, _], YesNo) :- YesNo = yes.
memory_current_cell_zero([C, _, _, _, _], YesNo) :- C \= 0, YesNo = no.

%% RUNNER
%% 
%% in BF, each instruction is run as it is encountered, except [ and ]
%% the [ and ] instructions are matched, with [ jumping forward to after
%% the matching ] if the value of the currently pointed to cell is 0,
%% and otherwise continuing into the next instruction.
%% 
%% we represent this by pushing the remaining program whenever we
%% encounter a [ into a stack, and then popping off that stack based
%% on the value of the current pointer. this seems wasteful, but the
%% lists are immutable, and will share their structure completely,
%% with each pushed item merely acting as a pointer into the list
%% 
%% the runner executes the program, manipulating memory using the 
%% helpers we defined above.
%% 
%% the program is done when the program is empty. in effect, we're having
%% prolog search for how to get to an empty program

% PP - the remaining program to run
% LL - a list of remaining programs to run, pushed to by _sl and popped by _el

runner(MM,PP,RR) :- RR = [ MM, PP, [] ].

runner_step([ MM, []     , []]   , Out) :- memory_out( MM, Out ).

runner_step([ MM, [lt|PP], SS], Out) :- memory_lt(MM,NewMM), runner_step([ NewMM, PP, SS], Out).
runner_step([ MM, [rt|PP], SS], Out) :- memory_rt(MM,NewMM), runner_step([ NewMM, PP, SS], Out).
runner_step([ MM, [up|PP], SS], Out) :- memory_up(MM,NewMM), runner_step([ NewMM, PP, SS], Out).
runner_step([ MM, [dn|PP], SS], Out) :- memory_dn(MM,NewMM), runner_step([ NewMM, PP, SS], Out).
runner_step([ MM, [rd|PP], SS], Out) :- memory_rd(MM,NewMM), runner_step([ NewMM, PP, SS], Out).
runner_step([ MM, [wr|PP], SS], Out) :- memory_wr(MM,NewMM), runner_step([ NewMM, PP, SS], Out).

% we've reached the start of a loop. if the value of the current cell is 0, we skip it
% otherwise, we enter into it and loop at the end. we push the current program into the
% stack if we enter to allow popping back to that location later
%
runner_step([ MM, [sl|PP], SS], Out) :-
    memory_current_cell_zero( MM, YesNo ),
    runner_advance_after_or_enter_loop( YesNo, MM, PP, SS, Out ).

% we reached the end of a loop, just pop off the start of the loop from the stack and continue from there
% it will immediately decide whether to go into the loop again or not
% 
runner_step([ MM, [el|_], [PP|SS]], Out ) :-
    runner_step([ MM, PP, SS ], Out ).

% the helpers for sl handling

% cell was 0, advance after
runner_advance_after_or_enter_loop( yes, MM, PP, SS, Out ) :-
    after_el( PP, AA ),
    runner_step([ MM, AA, SS], Out).

% cell was non-0, enter loop pushing the current location onto the stack so we can pop to it later
% PP has the sl popped off from hitting the runner step above, so we tack it back on
runner_advance_after_or_enter_loop( no, MM, PP, SS, Out ) :-
    runner_step( [MM, PP, [[sl|PP]|SS]], Out ).

% return the program after the end of the current loop
%   for a loop [+]-- 
%   we receive +]--
%   and should return --
%   but!
%   if we receive ++[-]++]--
%   we should still return --, since we must skip the fully enclosed loop!
%   to do this we add a depth counter and skip over ]'s when our counter isn't 0

after_el(PP, Match) :- ael(PP, 0, Match).

ael([]     , _, Match) :- Match = []. % BF error, [ has no matching ], return the end of the program
ael([el|PP], 0, Match) :- Match = PP.
ael([el|PP], N, Match) :- D is N - 1, ael( PP, D, Match ).
ael([sl|PP], N, Match) :- S is N + 1, ael( PP, S, Match ).
ael([_ |PP], N, Match) :- ael( PP, N, Match ).

%%%%%

run( PP, II, Out ) :-
    memory( II, MM ),              % mm out
    runner( MM, PP, RR ),          % mm and pp in, rr out
    runner_step( RR, ReverseOut ), % rr in, out... out
    reverse( ReverseOut, Out).

%%%%%

% hello world from wikipedia
% 
helloworld(P) :- P =
                 [
                     up,up,up,up,up,up,up,up,sl,rt,up,up,up,up,sl,rt,up,up,rt,up,up,
                     up,rt,up,up,up,rt,up,lt,lt,lt,lt,dn,el,rt,up,rt,up,rt,dn,rt,rt,
                     up,sl,lt,el,lt,dn,el,rt,rt,wr,rt,dn,dn,dn,wr,up,up,up,up,up,up,
                     up,wr,wr,up,up,up,wr,rt,rt,wr,lt,dn,wr,lt,wr,up,up,up,wr,dn,dn,
                     dn,dn,dn,dn,wr,dn,dn,dn,dn,dn,dn,dn,dn,wr,rt,rt,up,wr,rt,up,up,
                     wr 
                 ].

%% makes sure we can loop
countdown(P) :- P =
                [
                    up,up,up,up,up,up,up,up,up,up,up,
                    sl,wr,dn,el
                ].

%% makes sure nested loops are working
countdown_nested(P) :- P =
                [
                    up,up,up,up,up,up,up,up,up,up,up,
                    sl,
                      wr,dn,lt,up,up,up,sl,wr,dn,el,rt,
                    el
                ].

:- helloworld( PP ),
   program( PP ),
   II = [],
   run( PP, II, Out ),
   format("~s~n", [Out]).
