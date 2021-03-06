(* ::Package:: *)

BeginPackage["SSS`"]

(* is this public? *)

SSS::usage = "Functions related to Sequential Substitution Systems (SSS) & Causal Network Construction."
 
 Begin["`Private`"]
  (* Build a causal network from a SSS, modeling the Sequential Substitution System using tags.  This allows us to build the SSS evolution and the causal network simultaneously.  
(Based on code from NKS, pp. 1033, and suggestions of Matthew Szudzik.) *)

(* Alphabet: fromAlpha, toAlpha, SSSConvert *)

fromAlpha[string_String] :=(ToCharacterCode[string]-65);  
toAlpha[l:{___Integer}] := FromCharacterCode[l+65];

Attributes[s]=Flat;
SSSConvert[string_String] := s @@ fromAlpha[string];
SSSConvert[s[x__]] := toAlpha[{x}];
SSSConvert::usage="Converts SSS (sequential substitution system) states between s- and string-formats, using the functions \!\(\*
StyleBox[\"fromAlpha\",\nFontSlant->\"Italic\"]\) and \!\(\*
StyleBox[\"toAlpha\",\nFontSlant->\"Italic\"]\).";

(* If it is considered desirable to use a different alphabet, only the functions fromAlpha and toAlpha need be changed.  
The only requirement is that the alphabet be enumerable, i.e., set in 1-1 correspondence with {0,1,2,\[Ellipsis]}. *)

(* Character, string, ruleset weight & ruleset length:  ToCharacterWeights, FromCharacterWeights, StringWeight, RuleSetWeight, RuleSetLength *)

(* For later iteration through the complete enumeration of rulesets, we require the weight of a character, a string or 
a ruleset.  The weight of a character is closely akin to what is already done by the fromAlpha function, but with 
A\[Rule]1, B\[Rule]2, etc., reserving 0 for the weight of the empty string.  The weight of a string is the sum of the weights of its 
characters, and the weight of a ruleset is sum of the weights of its strings: *)

ToCharacterWeights[s_String] := (1+fromAlpha[s]);
FromCharacterWeights[l:{___Integer}] := toAlpha[l-1];
(* Note: To avoid breaking the ruleset (un-)rank functions, avoid the temptation to define:  
ToCharacterWeights[""] = 0;  FromCharacterWeights[{0}]="";  *)
StringWeight[s_String] := Plus @@ ToCharacterWeights[s];
RuleSetWeight[rs_List] := Plus @@ (StringWeight /@ Flatten[rs /. Rule->List]);
RuleSetLength[rs_List] := Plus @@ (StringLength /@ Flatten[rs /. Rule->List]);
 
 (* Now StringWeight can be applied to either strings or characters (single-character strings): *)
 
 (* RuleSetWeight and the comparably defined RuleSetLength give the sum of the weights or sum of 
     the lengths, respectively, of the strings in the ruleset: *)
 
 (* SSSRuleIcon (defines & uses $MaxColor, myColors, patternPrint) *)
 
 $MaxColor=6;  
 
 (* If you want to display SSSs with more than 6 symbols, just change this variable, otherwise the colors wrap.  
    (Now SSSInititialize modifies this automatically.) *)
 
 myColors=Sequence[ColorFunction->(Hue[(#-1)/$MaxColor]&),ColorFunctionScaling->False];
 
 patternPrint[pattern_,opts___] := ArrayPlot[{{##}/. 0->LightGray}& @@pattern,myColors,Mesh->True,opts,ImageSize->{Automatic,20}];
 
 Clear[SSSRuleIcon];
SSSRuleIcon[(rule_String|rule_Rule|rule_RuleDelayed),x___]:=SSSRuleIcon[{rule},x];

SSSRuleIcon[rules_List,x___]:=SSSRuleIcon[Map[SSSConvert,rules,{-1}],x] /; !FreeQ[rules,_String,Infinity];

SSSRuleIcon[rules_List,opts___] := Panel[Grid[Map[patternPrint[#,opts]&,rules,{2}] /. 
{Rule[x_,y_]:>{x,"\[AlignmentMarker]\[Rule]",y},RuleDelayed[x_,y_]:>{x,"\[AlignmentMarker]\[RuleDelayed]",y}}, (* invisible AlignmentMarkers! *)
Alignment->Left],"Substitution Rule"<>If[Length[rules]>1,"s:",":"]] /; FreeQ[rules,_String,Infinity];

SSSRuleIcon::usage="SSSRuleIcon[\!\(\*
StyleBox[\"rule\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\"(\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\"s\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\")\",\nFontSlant->\"Italic\"]\)] generates an icon for a sequential substitution system (SSS) rule or set of rules.";

(* Generate a ruleset for the tagged SSS: SSSNewRule *)

(* We need a convenient way to convert old style rulesets (using letters only) to a new style ruleset, with the ability to handle tags.  
For example, "BA"\[Rule]"ABA" or s[1,0]\[Rule]s[0,1,0] should be rewritten as *)

(* s[{1, a_}, {0, b_}] \[RuleDelayed] (AppendTo[$SSSConnectionList, {a, b} \[Rule] $SSSTagIndex + {0, 1, 2}];  s[{0, $SSSTagIndex++}, {1, $SSSTagIndex++}, {0, $SSSTagIndex++}]) *)

SSSNewRule[rule_Rule | rule_RuleDelayed] := Module[{lhs,rhs,lhsNames,newlhs,newrhs1,newrhs2},
{lhs,rhs}=List@@rule;
lhsNames = Table[Unique[lhsTag],{StringLength[lhs]}];
newlhs=ToString[s@@Transpose[{fromAlpha[lhs],ToString@#<>"_"& /@ lhsNames}]];
newrhs1=("AppendTo[$SSSConnectionList, "<>ToString[lhsNames]<>" \[Rule] $SSSTagIndex + "<>ToString[Range@StringLength@rhs-1]<>"]; ");
newrhs2=ToString[SSSConvert[rhs] /. n_Integer :> {n,"$SSSTagIndex++"}];
ToExpression[newlhs<>" \[RuleDelayed] ("<>newrhs1<>newrhs2<>")"]];
SSSNewRule[rules_List] := SSSNewRule/@rules;
SSSNewRule::usage= 
"SSSNewRule[\!\(\*
StyleBox[\"rule\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\"(\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\"s\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\")\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\"]\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"generates\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"the\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"needed\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"rule\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"(\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"s\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\")\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"for\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"the\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"tagged\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\"SSS\",\nFontSlant->\"Plain\"]\)\!\(\*
StyleBox[\" \",\nFontSlant->\"Plain\"]\)(sequential substitution system) from the \!\(\*
StyleBox[\"rule\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\"(\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\"s\",\nFontSlant->\"Italic\"]\)\!\(\*
StyleBox[\")\",\nFontSlant->\"Italic\"]\) given in string-format: e.g., \"BA\"\[Rule]\"ABA\"";

(* Stripping out tags: SSSStrip *)

(* Internally an SSS state will include not only information about the cells/letters, but in addition, unique identifiers or tags.  For 
visualization purposes a one-way conversion from tagged to untagged form will be needed.  Here's a convert/strip function to strip out 
tags and recover the String notation: *)

Clear[SSSStrip];
SSSStrip[x_s] := SSSConvert[x[[All,1]]] /; MatrixQ[List@@x]   (* if dim=2, take only 1st component, and convert *)
SSSStrip[s[]]=""   (* treat empty string case *)  ;
SSSStrip::usage="SSSStrip[\!\(\*
StyleBox[\"state\",\nFontSlant->\"Italic\"]\)] strips out tags from a \!\(\*
StyleBox[\"state\",\nFontSlant->\"Italic\"]\) given in tagged SSS (sequential substitution system) format and returns it in string format.";

(* Some needed functions to deal with the strings & cells:  *)

(* cellsDeleted, safeStringTake, abbrev, envelopeSubtractStrings *)

cellsDeleted[{l1_,l2_}] := Flatten[Position[l1,_?(!MemberQ[l2,#]& ),{1},Heads->False] ];

safeStringTake[s_String,{n1_Integer,n2_Integer}] := StringTake[s,{Max[1,n1],Min[StringLength[s],n2]}];
safeStringTake[s_String,{n1_Integer,n2_Integer}] := safeStringTake[s,{StringLength[s]+1+n1,n2}]  /; -StringLength[s]<=n1<0
safeStringTake[s_String,{n1_Integer,n2_Integer}] := safeStringTake[s,{n1,StringLength[s]+1+n2}]  /; -StringLength[s]<=n2<0

(* abbrev[string] now always returns a list of 2 strings, the beginning and ending of string *)

abbrev[s_String,n_Integer] :={safeStringTake[s,{1,n}],safeStringTake[s,{-n,-1}]};
abbrev[s_String,0]:= {"",""};
 (* use as "abbreviation" of long strings the list of substrings of the first & last n characters *)
 
abbrev[s_String,n_] := (Print[Stack[]];s)  (* anything else happens, let's debug! *)

envelopeSubtractStrings[big_String,little_String] := Module[{lenbig=StringLength[big],lenlittle=StringLength[little],i=1,j=1,bigc=Characters[big],littlec=Characters[little]},
If[lenbig<lenlittle,Return[Reverse[envelopeSubtractStrings[little,big]]]];
For[i=1,i<=lenlittle,i++,If[bigc[[i]]!=littlec[[i]],Break[]]];  (* now i is the first NON-matching character, or lenlittle + 1 *)
For[j=1,j<=lenlittle+1-i,j++,If[bigc[[-j]]!=littlec[[-j]],Break[]]]; (* now j is the first non-matching character starting from the end, 
or the first character that matched from the beginning *)
{StringJoin @ bigc[[;;i-1]],StringJoin /@ Rule[littlec[[i;;-j]],bigc[[i;;-j]]],StringJoin @ bigc[[-j+1;;]]};
{{i,-j},StringJoin /@ Rule[littlec[[i;;-j]],bigc[[i;;-j]]]};
StringJoin /@ Rule[littlec[[i;;-j]],bigc[[i;;-j]]]
]; (* returns a list of replacements made *)

(* SSSInitialize (revamped):  Initializing globals *)

(* Creating a causal network from a tagged SSS system requires at least two global variables, $SSSConnectionList and $SSSTagIndex, so we 
might as well keep track of other useful things in global variables, to avoid unnecessary recomputations.  (Now adjusts $MaxColor up/down as needed.) *)

(* SSSInitialize now does first single-step, checks for death (removes need for SSSSingleStep verifying that SSSEvolution and SSSTEvolution 
have at least 2 elements, and that SSSConnectionList has at least 1 element.  Returns True|False and optionally prints a clarifying message. *)

SSSInitialize[rs:{___Rule},state_String,mode_:"Silent" (* "Silent" | "Loud" *)] :=
(
(* Tweak $MaxColor *)
$MaxColor:=Max[Flatten[{6,ToCharacterWeights /@ Flatten[rs/.Rule->List]}]];
(* initial setup *)
$SSSNet={};
$SSSOutDegreePotential=$SSSOutDegreeRemaining=$SSSOutDegreeActual={};
$SSSInDegree={}; (* {0} will be starting with one node, of in-degree 0 *)
$SSSDistance={0}; (* The starting node is 0 steps away from the starting node *)
$SSSConnectionList={}; 
$SSSTagIndex=StringLength[state]+1;                     (* value of next tag to use *)
$SSSTEvolution={s@@Transpose[{#,Range[Length[#]]}& @ fromAlpha[state]]};
$SSSEvolution = {state};
$SSSRuleSet = rs;
$SSSTRuleSet =SSSNewRule[rs];
$SSSRuleSetWeight = RuleSetWeight[rs];
$SSSRuleSetLength = RuleSetLength[rs];
$SSSMatchLengthHistory = $SSSHistory = {};
$SSSRepetitionInterval = $SSSRepetitionStart = 0;
$SSSStart = 1;
$SSSVerdict = "";
$SSSRuleUsage=Table[0,{Length[rs]}];  (* none of the rules have been used as yet *)

(* now do first singlestep, so we have at least 2 strings for the 
comparison tests used to determine $SSSVerdict and to build $SSSOutDegreeActual and $SSSOutDegreeRemaining *)
AppendTo[$SSSTEvolution,Last[$SSSTEvolution]/.$SSSTRuleSet];
AppendTo[$SSSEvolution,SSSStrip[Last[$SSSTEvolution]]];

If[ !MatchQ[mode, ("Silent"|"Quiet")],
Switch[Length[$SSSConnectionList],
0,Print["Error: No evolution possible starting from \""<>state<>"\" using ruleset: ",rs];Return[False],
_,Print["Successful initialization of ruleset: ",rs,", evolution: ",$SSSEvolution]
]
];

(* or if the first step of the evolution worked, update the global variables: *)
updateHistory;  (* $SSSOutDegreePotential, $SSSOutDegreeRemaining, $SSSOutDegreeActual, $SSSMatchLengthHistory, $SSSHistory, $SSSRuleUsage *)
True  (* = Success *)
);

(* Below is code that must be executed each time a step is performed by SSSSingleStep, but it must also be done after for the first 
step, done by SSSInitialize, so it has been put into a separate function that both can call, updating $SSSOutDegreePotential, 
$SSSOutDegreeRemaining, $SSSOutDegreeActual, $SSSMatchLengthHistory, $SSSHistory. *)

updateHistory := Module[{cd},
AppendTo[$SSSInDegree,Length[$SSSConnectionList[[-1,1]]]];  (* # cells killed by this event = in-degree *)
(* calculate potential outdegree of new event, append to list *)
AppendTo[$SSSOutDegreePotential,Length[$SSSConnectionList[[-1,-1]]]];  (* # of cells created by last rule *)
AppendTo[$SSSOutDegreeRemaining,Last[$SSSOutDegreePotential]];
AppendTo[$SSSOutDegreeActual,0];

(* find cells deleted by latest event, use info to update $SSSHistory and $SSSMatchLengthHistory *)
cd=cellsDeleted[$SSSTEvolution[[-2;;]]];  (* comparing last 2 states, find deleted cell positions *)
cd=If[Length[cd]==0,{1,0},{First@cd,Last@cd}];  (* Take first & last or if no deletions -- there was an insertion at beginning of 
state string: match at pos 1, length 0 *)

(* $SSSMatchLengthHistory gets 3 numbers: lengths of pre-match, match, and post-match substrings *)
AppendTo[$SSSMatchLengthHistory,{First[cd]-1,Last[cd]-First[cd]+1,StringLength[$SSSEvolution[[-2]]]-Last[cd]}];

(* $SSSHistory gets 4 items: pre-match abbreviation, match rule #, post-match abbreviation, 0 *)
AppendTo[$SSSHistory,{
abbrev[#,$SSSRuleSetLength]& @ safeStringTake[$SSSEvolution[[-2]],{1,First[cd]-1}],  (* pre-match substring *)
StringTake[$SSSEvolution[[-2]],cd] /. Thread[$SSSRuleSet[[All,1]]->Range[Length[$SSSRuleSet]]],  (* matching rule # *)
(* Print["Trying to do safeStringTake[$SSSEvolution\[LeftDoubleBracket]-2\[RightDoubleBracket],{Last[cd]+1,-1}]: safeStringTake[",$SSSEvolution\[LeftDoubleBracket]-2\[RightDoubleBracket],", {Last[",cd,"} ]+1,-1}]"]; *)
abbrev[#,$SSSRuleSetLength]& @ safeStringTake[$SSSEvolution[[-2]],{Last[cd]+1,-1}],     (* post-match substring *)
0  (* tag to be used later to indicate shrinkage before/after match *)
}];
If[$SSSVerdict=!="Dead",$SSSRuleUsage[[$SSSHistory[[-1,2]]]]++ ] (* increment the usage counter for the rule that was used on this step *)
];

SSSInitialize::usage = "SSSInitialize[ruleset,string,(mode)] attempts to perform the necessary initializion steps to generate sequential substitution system (SSS) evolutions and networks,\nstarting with a ruleset (e.g., {\"BA\"\[Rule]\"ABA\"}) and an initial state string (e.g., \"BABA\").  The True|False return value indicates whether initialization was successful.\n\nIf omitted, mode defaults to \"Silent\", suppressing the short error or success message.\n\nThe following global variables are reset by this operation:\n\n$SSSNet:\t\t\t\tthe causal network of the current SSS,\n$SSSInDegree:\t\t\tthe list of in-degrees for each node,\n$SSSOutDegreeActual:\t\tthe list of currently found out-degrees for each node,\n$SSSOutDegreePotential:\t\tthe list of maximum possible out-degrees for each node,\n$SSSOutDegreeRemaining:\tthe list of numbers of possible remaining out-connections for each node,\n$SSSConnectionList:\t\tthe current list of all causal network connections,\n$SSSDistance:\t\t\tthe list of minimum distances from the current node back to the starting node.\n$SSSTagIndex:\t\t\tthe current tag index being used,\n$SSSTEvolution:\t\t\tthe complete evolution of the tagged SSS so far,\n$SSSEvolution:\t\t\tthe stripped (tagless) version of $SSSTEvolution,\n$SSSRuleSet:\t\t\tthe ruleset used for creating the SSS,\n$SSSTRuleSet:\t\t\tthe version of $SSSRuleSet (created by the function SSSNewRule) used to build $SSSTEvolution,\n$SSSRuleSetWeight:\t\tthe total weight of $SSSRuleSet,\n$SSSRuleSetLength:\t\tthe total length of $SSSRuleSet,\n$SSSHistory:\t\t\tan annotated/translated version of $SSSEvolution used to detect repeating patterns,\n$SSSMatchLengthHistory:\ta list of the match positions that occurred in forming the SSS,\n$SSSRuleUsage:\t\t\tthe list of rule usage counters, later adjusted to identified portion of SSS,\n$SSSRepetitionInterval:\t\tthe length of the repeating section (if any) of the SSS,\n$SSSRepetitionStart:\t\tthe start of the repeating section (if any) of the SSS,\n$SSSStart:\t\t\tthe starting position for displaying the SSS and its causal network,\n$SSSVerdict:\t\t\tset to \"Dead\" | \"Repeating\" | \"Pseudorepeating\" as soon as the future of the SSS becomes clear.";

(* SSSSingleStep (revamped): *)

(* SSSSingleStep no longer has \[OpenCurlyDoubleQuote]modes\[CloseCurlyDoubleQuote]:  if you call it, you want the full package treatment:  evolve the SSS ($SSSTEvolution and $SSSEvolution) 
and causal network ($SSSConnectionList, $SSSNet), update node info ($SSSOutDegreePotential, $SSSOutDegreeRemaining, $SSSOutDegreeActual), and 
distance list ($SSSDistance).  No need to verify whether $SSSEvolution has at least 2 entries, and $SSSConnectionList at least 1, since this is 
now guaranteed if SSSInitialize returns True.  Updating $SSSVerdict is a separate task to be moved to PronounceVerdict, called after each 
evolution step (to catch dead [important!] | repeating cases immediately).  But note that only if the SSS is dead does SSSSingleStep return False 
and refuse to proceed. *)

(* SSSSingleStep now updates the tags (column 4) in $SSSHistory, might as well do it as we go since each tag only depends on two successive lines.  
(These tags used by the new function VerifyPseudorepeating.) *)

(* SSSSingleStep now refuses to modify anything if the SSS is already dead, and calls PronounceVerdict after each step, so Dead | Repeating cases 
are guaranteed to be caught immediately.  The main disadvantage is slightly slower execution, but the problem is limited by making PronounceVerdict 
return immediately if a verdict already exists. *)

SSSSingleStep := Module[{cd, ri, pri, rs, prs,len,startingEvents},
If[$SSSVerdict==="Dead",Return[False]];  (* if already dead, do nothing *)

(* do the actual evolution step *)
AppendTo[$SSSTEvolution,Last[$SSSTEvolution]/.$SSSTRuleSet];
AppendTo[$SSSEvolution,SSSStrip[Last[$SSSTEvolution]]];

If[!MatchQ[$SSSVerdict,"Dead"|"Repeating"],PronounceVerdict];  (* to limit wasted time, don't call if verdict is already in! *)

If[$SSSVerdict==="Dead",Return[False]];  (* if died this step, return immediately:  fixes BUG! extra link was added after sessie died *)

(* Now update globals:  first the part that is done for each step, including the first one (by SSSInitialize): *)
updateHistory; (* $SSSOutDegreePotential, $SSSOutDegreeRemaining, $SSSOutDegreeActual, $SSSMatchLengthHistory, $SSSHistory *)

(* now the steps that are only done for non-initial steps, comparing to previous entries in $SSSConnectionList: *)
len=Length[$SSSConnectionList];
startingEvents=Flatten[If[Length[#]>0,First[First[#]],#]& /@ (Position[$SSSConnectionList[[;;-2]],#]& /@ $SSSConnectionList[[-1,1]])];
$SSSOutDegreeActual[[#]]++& /@ startingEvents; (* update out-degee list for events involved *)
$SSSOutDegreeRemaining[[#]]--& /@ startingEvents; (* update out-degee list for events involved *)
$SSSNet=Join[$SSSNet,#->len& /@ startingEvents];           (* add new links to the causal network *)

AppendTo[$SSSDistance,Min[$SSSDistance[[startingEvents]]]+1];  (* Find minimum path length of cause nodes, add 1 *)

(* fix tag: 4th item of current line of $SSSHistory *)
If[Length[$SSSMatchLengthHistory]>1,
Switch[$SSSMatchLengthHistory[[-1]]-$SSSMatchLengthHistory[[-2]], (* compare to previous line *)
{_?Negative,0,_},$SSSHistory[[-1,4]]=$SSSHistory[[-2,4]]+1,  (* prematch shrinking *)
{_,0,_?Negative},$SSSHistory[[-1,4]]=$SSSHistory[[-2,4]]-1     (* postmatch shrinking *)
]
];

Return[True];
];

SSSSingleStep::usage=
"SSSSingleStep performs a single step of the current sequential substitution system (SSS) evolution (if not already dead), applying the current SSS ruleset (saved in $SSSRuleSet and $SSSTRuleSet) to the most recent state, the last entry in $SSSTEvolution and $SSSEvolution.  This operation updates the global variables $SSSConnectionList, $SSSTagIndex, $SSSTEvolution, $SSSEvolution, $SSSHistory, $SSSMatchLengthHistory, $SSSRuleUsage, $SSSVerdict, $SSSOutDegreePotential, $SSSOutDegreeRemaining, $SSSOutDegreeActual,$SSSDistance.  Use SSSInitialize to set up the global variables.";

(* PronounceVerdict *)

(* Separate function to test the current SSS at the current point in its evolution, and save the result in $SSSVerdict, as well as updating 
$SSSRepetitionStart and $SSSRepetitionInterval.  Must not be called until the SSS has been initialized by SSSInitialize and at least one 
step made by SSSSingleStep, since we assume that Length[$SSSTEvolution] > 1 (true after initialization) and Length[$SSSHistory] > 1 (true 
after first call to SSSSingleStep).  Verdict options:  \[OpenCurlyDoubleQuote]Dead\[CloseCurlyDoubleQuote], \[OpenCurlyDoubleQuote]Repeating\[CloseCurlyDoubleQuote] and \[OpenCurlyDoubleQuote]Pseudorepeating\[CloseCurlyDoubleQuote].  Returns {$SSSVerdict, {$SSSRepetitionStart, 
$SSSRepetitionInterval}.  SSSSingleStep checks $SSSVerdict before each actual evolution step and calls this function after each step if 
$SSSVerdict is the empty string in order to update $SSSVerdict, but it ignores the output, which is mostly for the benefit of the human operator. *)

(* 
Returns:

\[OpenCurlyDoubleQuote]Dead\[CloseCurlyDoubleQuote]		(last 2 elements of $SSSTEvolution are identical),
\[OpenCurlyDoubleQuote]Repeating\[CloseCurlyDoubleQuote]		(last element of $SSSEvolution is identical to some earlier element: slower test, but time-saving if it works),
\[OpenCurlyDoubleQuote]Pseudorepeating\[CloseCurlyDoubleQuote]	(last element of $SSSHistory = at least 3 earlier elements, inconclusive, use VerifyPseudorepeating to test),

-- unless a verdict has already been pronounced.  Side effects:  sets $SSSVerdict, $SSSRepetitionStart, $SSSRepetitionInterval (0 if \[OpenCurlyDoubleQuote]Dead\[CloseCurlyDoubleQuote]).
*)

PronounceVerdict := Module[{matches,poslist},
Which[
MatchQ[$SSSVerdict,"Dead"|"Repeating"],{$SSSVerdict,{$SSSRepetitionStart,$SSSRepetitionInterval}},  (* Dead/Repeating SSSs don't ever 
change their spots. Otherwise, check/recheck: *)

Last[$SSSTEvolution]===$SSSTEvolution[[-2]],(* Dead, since last check *)
poslist=Flatten@Position[$SSSTEvolution,Last@$SSSTEvolution];
{$SSSVerdict,{$SSSRepetitionStart,$SSSRepetitionInterval}}={"Dead",{First[poslist],0}},

Length[poslist=Flatten@Position[$SSSEvolution,Last[$SSSEvolution]]]>1, (* Repeating, since last check *)
{$SSSVerdict,{$SSSRepetitionStart,$SSSRepetitionInterval}}={"Repeating",{First[poslist],poslist[[-1]]-poslist[[-2]]}};
(* Print["rule usage: ",$SSSRuleUsage]; *)
$SSSRuleUsage=Table[0,{Length[$SSSRuleSet]}]; (* Zero out rule usage counters *)
Do[$SSSRuleUsage[[$SSSHistory[[k,2]]]]++,{k,$SSSRepetitionStart,Length[$SSSHistory]}]; (* count only identified part *)
(* Print["rule usage: ",$SSSRuleUsage]; *)
{$SSSVerdict,{$SSSRepetitionStart,$SSSRepetitionInterval}},

(* Note that the above tests take precedence over Pseudorepeating *)

$SSSVerdict=!="", {$SSSVerdict,{$SSSRepetitionStart,$SSSRepetitionInterval}}, (* Verdict already pronounced, stick with it *)

poslist=Flatten@Position[$SSSHistory,Last[$SSSHistory]];
Length[poslist]>=5, (* We may enough repeats in the history to test *)
{$SSSVerdict,{$SSSRepetitionStart,$SSSRepetitionInterval}}={"Pseudorepeating",{First[poslist],poslist[[-1]]-poslist[[-2]]}},

True, {$SSSVerdict,{$SSSRepetitionStart,$SSSRepetitionInterval}}
]]
(* SSSEvolve *)

(* And finally the evolve function, which will attempts do perform a specified number of single steps of the current SSS evolution, 
optionally returning early if a repetition or pseudo-repetition interval has been found.  Returns $SSSVerdict if a verdict has been 
pronounced, else \[OpenCurlyDoubleQuote]OK\[CloseCurlyDoubleQuote].  Use after initialization by SSSInitialize. *)

(* SSSEvolve now takes option EarlyReturn -> True | False *)

Options[SSSEvolve]={EarlyReturn->False};
SyntaxInformation[SSSEvolve]={"ArgumentsPattern"->{OptionsPattern[]}};

SSSEvolve[n_Integer/;n>0,opts:OptionsPattern[]] := (
If[OptionValue[EarlyReturn],
Do[If[MatchQ[$SSSVerdict, ("Dead"|"Repeating"|"Pseudorepeating")],Break[],SSSSingleStep],{n}],
Do[SSSSingleStep,{n}]
];
If[$SSSVerdict=="","OK",$SSSVerdict]
)
SSSEvolve::usage="SSSEvolve[\!\(\*StyleBox[\"n\",FontSlant->\"Italic\"]\)] generates an additional \!\(\*StyleBox[\"n\",FontSlant->\"Italic\"]\) levels of the \!\(\*StyleBox[\"current\",FontSlant->\"Plain\"]\)\!\(\*StyleBox[\" \",FontSlant->\"Plain\"]\)\!\(\*StyleBox[\"SSS\",FontSlant->\"Plain\"]\)\!\(\*StyleBox[\" \",FontSlant->\"Plain\"]\)(sequential substitution system), which must have been previously initialized using SSSInitialize.  Use the option EarlyReturn \[Rule] True (default) to allow early termination for repeating or pseudorepeating cases.  (SSSSinglestep immediately returns anyway if the SSS is dead.  Proposed pseudo-repeating cases are currently ignored.)  Returns the current verdict, or \"OK\" if none known.  Global variables set up by SSSInitialize are updated, with $SSSEvolution containing the tagless SSS, $SSSConnectionList the updated causal network connection list, etc.  mode can be \"Silent\", \"Quiet\", or \"Loud\".";

Options[SSSDisplay]=
{HighlightMethod->True,ShowRule->Bottom,Mesh->True,NetSize->{Automatic,500},SSSSize->{Automatic,300},IconSize->{Automatic,20},ImageSize->Automatic,NetMethod->GraphPlot,HideStart->False, (* False | True | Best *)  
Max->\[Infinity],SSSMax->Automatic,NetMax->Automatic,
Min->1,SSSMin->Automatic,NetMin->Automatic, 
DistanceMax->\[Infinity],
UseDistances->False,
Sequence@@Union[Options[TreePlot],Options[GraphPlot],Options[GraphPlot3D],Options[LayeredGraphPlot]]};
SyntaxInformation[SSSDisplay]={"ArgumentsPattern"->{OptionsPattern[]}};

SSSDisplay[opts:OptionsPattern[]] := Module[{HlM,SR,mesh,IcS,ImS,SS,NS,RP,NM,UD,DM,doGP,doLGP,doTP,doGP3D,doSSS,myNet,ans,cellsToHighlight,rulesApplied,mx,netmx,sssmx,mn,netmn,sssmn,hs,start,ev,net},

HlM =If[#===True,Number,#]& @ OptionValue[HighlightMethod]; 
SR=OptionValue[ShowRule];
mesh=OptionValue[Mesh];
SS = OptionValue[SSSSize];
IcS = OptionValue[IconSize];
ImS = OptionValue[ImageSize];
NS = OptionValue[NetSize];
NM=OptionValue[NetMethod];
hs=OptionValue[HideStart];

mx=OptionValue[Max];
If[mx===Automatic,mx=\[Infinity]];
sssmx=OptionValue[SSSMax]; 
If[sssmx===Automatic,sssmx=mx];
netmx=OptionValue[NetMax]; 
If[netmx===Automatic,netmx=mx];

mn=OptionValue[Min];
If[mn===Automatic,mn=1];
sssmn=OptionValue[SSSMin]; 
If[sssmn===Automatic,sssmn=mn];
netmn=OptionValue[NetMin]; 
If[netmn===Automatic,netmn=mn];

UD=OptionValue[UseDistances];
DM=OptionValue[DistanceMax];

Switch[hs,
True, start=Max[$SSSRepetitionStart,1]; netmx+=start-1; sssmx+=start-1,
Best, start=Max[BestNetStart,1]; netmx+=start-1; sssmx+=start-1,
False, start=1
];

net=(Select[$SSSNet,And@@Thread[Max[start,netmn]<=List@@#<=netmx]&] /. n_Integer:>(n+1-start));
If[UD||(DM<\[Infinity]),net=(net /.nn_Integer:>Subscript[$SSSDistance[[nn]],Style[nn,Tiny]])];
If[DM<\[Infinity],
net=Cases[net,r:Rule[Subscript[_?(#<=DM&),_],Subscript[_?(#<=DM&),_]]:> r];
If[!UD,net=(net /. Subscript[_,Style[n_Integer,_]]:>n)]
];

doGP=doLGP=doTP =doGP3D=False;doSSS=True;
If[MemberQ[NM,All,{0,\[Infinity]}],doGP=doLGP=doTP=doGP3D=True];
If[MemberQ[NM,GraphPlot,{0,\[Infinity]}],doGP=True];
If[MemberQ[NM,LayeredGraphPlot,{0,\[Infinity]}],doLGP=True];
If[MemberQ[NM,TreePlot,{0,\[Infinity]}],doTP=True];
If[MemberQ[NM,GraphPlot3D,{0,\[Infinity]}],doGP3D=True];
If[MemberQ[NM,NoSSS,{0,\[Infinity]}],doSSS=False];

If[hs && $SSSVerdict=="Dead",doGP=doLGP=doTP=doGP3D=False];

cellsToHighlight=Flatten[#,2]&@MapIndexed[Outer[List,#1,#2]&,Reverse[#[[1]]+Range[#[[2]]]& /@ ($SSSMatchLengthHistory[[Max[start,sssmn];;Min[sssmx-1,Length[$SSSMatchLengthHistory]]]] )]];
(* #\[LeftDoubleBracket]1\[RightDoubleBracket]+Range[#\[LeftDoubleBracket]2\[RightDoubleBracket]]& /@ $SSSMatchLengthHistory generates a list of the cells deleted at each step *)
rulesApplied=Reverse[$SSSHistory[[Max[start,sssmn];;Min[sssmx-1,Length[$SSSHistory]],2]] ];
ans = 
ArrayPlot[(fromAlpha/@ $SSSEvolution[[Max[start,sssmn];;Min[sssmx,Length[$SSSEvolution]]]])/. 0->LightGray,myColors,Mesh->mesh,ImageSize->SS,
Epilog->Switch[HlM,
Dot,Disk[#+0.5{-1,1},.18]& /@ cellsToHighlight,
Frame,{EdgeForm[Thick],FaceForm[],Rectangle[#-{1,0}]& /@ cellsToHighlight},
Number,Text @@@ (cellsToHighlight /. {x_Integer,y_Integer}:>{rulesApplied[[y]],{x,y}+.5{-1,1}}),
_,{}]];
Row[Flatten@{
If[!doSSS,{},Pane[
Switch[SR,
Right, Row[{ans," ",SSSRuleIcon[$SSSRuleSet,ImageSize->IcS]}],
Left, Row[{SSSRuleIcon[$SSSRuleSet,ImageSize->IcS]," ",ans}], 
Bottom|True, Column[{ans," ",SSSRuleIcon[$SSSRuleSet,ImageSize->IcS]}], 
Top,  Column[{SSSRuleIcon[$SSSRuleSet,ImageSize->IcS]," ",ans}], 
_,ans],ImageSize->ImS,ImageSizeAction->"ShrinkToFit"]],
If[doGP,GraphPlot[net,Sequence@@Flatten[{ImageSize->NS,FilterRules[{opts}, Options[GraphPlot]],VertexLabeling->True}]],{}],
If[doLGP,LayeredGraphPlot[net,Sequence@@Flatten[{ImageSize->NS,FilterRules[{opts}, Options[LayeredGraphPlot]],VertexLabeling->True}]],{}],
If[doTP,TreePlot[net,Top,1,Sequence@@Flatten[{ImageSize->NS,FilterRules[{opts}, Options[TreePlot]],VertexLabeling->True,DirectedEdges->True}]],{}],
If[doGP3D,GraphPlot3D[net,Sequence@@Flatten[{ImageSize->NS,FilterRules[{opts}, Options[GraphPlot3D]],VertexLabeling->True}]],{}]
},"  "]]
   
SSSDisplay::usage="SSSDisplay[\!\(\*StyleBox[\"opts\",FontSlant->\"Italic\"]\)] displays the current SSS (sequential substitution system) and/or SSS causal network, typically after a call to SSS (or to SSSInitialize and SSSEvolve).

Options:
\tHideStart \[Rule] True | False | Best determines whether any initial, non-(pseudo-)repeating part of the SSS and/or causal network is suppressed.
\tMin \[Rule] \!\(\*StyleBox[\"n\",FontSlant->\"Italic\"]\) cuts off the display before the first \!\(\*StyleBox[\"n\",FontSlant->\"Italic\"]\) steps of the system.  (Separate values can be specified for SSSMin and NetMin.)
\tMax \[Rule] \!\(\*StyleBox[\"n\",FontSlant->\"Italic\"]\) cuts off the display after the first \!\(\*StyleBox[\"n\",FontSlant->\"Italic\"]\) steps of the system.  (Separate values can be specified for SSSMax and NetMax.)
\tUseDistances \[Rule] False | True determines whether vertex distances are displayed with subscripted node numbers.

\tHighlightMethod \[Rule] Dot | Frame | Number (or True) | None (or False) specifies how the matches in the SSS are highlighted. 

\tShowRule \[Rule] Bottom | Top | Left | Right | None (or False) specifies where to place the rulelist icon relative to the SSS visual display (if shown).  

\tSizes of display components are specified by the options NetSize, SSSSize, IconSize and ImageSize (which refers to the pane containing the SSS display and icon).

\tNetMethod \[Rule] GraphPlot | LayeredGraphPlot | TreePlot | GraphPlot3D | All | NoSSS | list of methods, \n\t\twhere NoSSS generates no SSS display (causal network only) and the other choices specify how the causal network is to be shown.  

(This function uses data stored in the global variables $SSSRuleSet, $SSSEvolution, $SSSHistory, $SSSMatchLengthHistory, and $SSSNet.)";   
   
(* SSSInteractiveDisplay: Interactive use of common options for SSSDisplay *)

SSSInteractiveDisplay := With[{mxmx=Max[List @@@ $SSSNet]},
Manipulate[
If[mx<mn,mx=mn+1];
If[sssmx<sssmn,sssmx=sssmn+1];
If[ntmx<ntmn,ntmx=ntmn+1];
SSSDisplay[HideStart->hs,Min->mn,Max->mx,SSSMin->(sssmn/. 0->Automatic),SSSMax->(sssmx/. mxmx+1->Automatic),NetMin->(ntmn/. 0->Automatic),NetMax->(ntmx/.mxmx+1->Automatic),HighlightMethod->hlm,ShowRule->sr,NetMethod->Flatten[{nm,If[no,{NoSSS},{}]}],ImageSize->is,NetSize->{Automatic,ns},SSSSize->{Automatic,ssss},IconSize->{Automatic,cns},VertexLabeling->If[vl,Tooltip,True]],
Grid[{{
Control[{{hlm,Number,"HighlightMethod"},{Dot,Frame,Number,None}}],
Control[{{sr,Bottom,"ShowRule"},{Bottom,Top,Left,Right}}],
Control[{{nm,GraphPlot,"NetMethod"},{GraphPlot,LayeredGraphPlot,TreePlot,GraphPlot3D,All}}],
Button["Save these options",
CellPrint[ExpressionCell[Defer[SSSDisplay][HideStart->hs,Min->mn,Max->mx,SSSMin->(sssmn/. 0->Automatic),SSSMax->(sssmx/. mxmx+1->Automatic),NetMin->(ntmn/. 0->Automatic),NetMax->(ntmx/.mxmx+1->Automatic),HighlightMethod->hlm,ShowRule->sr,NetMethod->Flatten[{nm,If[no,{NoSSS},{}]}],ImageSize->is,NetSize->{Automatic,ns},SSSSize->{Automatic,ssss},IconSize->{Automatic,cns},VertexLabeling->If[vl,Tooltip,True]],"Input"]];
SelectionMove[InputNotebook[],Previous,Cell];
]
}},Spacings->2],
Grid[{{Control[{{mn,1,"Min"},1,mxmx,1,Appearance->"Labeled"}],Control[{{mx,mxmx,"Max"},1,mxmx,1,Appearance->"Labeled"}],Control[{{no,False,"NoSSS"},{False,True}}]},
{Control[{{sssmn,0,"SSSMin"},0,mxmx,1,Appearance->"Labeled"}],Control[{{sssmx,mxmx+1,"SSSMax"},0,mxmx+1,1,Appearance->"Labeled"}],"(a NetMethod option)"},{Control[{{ntmn,0,"NetMin"},0,mxmx,1,Appearance->"Labeled"}],Control[{{ntmx,mxmx+1,"NetMax"},0,mxmx+1,1,Appearance->"Labeled"}],""},
{Control[{{cns,20,"IconSize"},10,50,Appearance->"Labeled"}],Control[{{is,350,"ImageSize"},10,500,Appearance->"Labeled"}],Control[{{vl,True,"VertexLabeling\[Rule]Tooltip"},{False,True}}]},
{Control[{{ssss,220,"SSSSize"},10,500,Appearance->"Labeled"}],Control[{{ns,400,"NetSize"},10,800,Appearance->"Labeled"}],Control[{{hs,False,"HideStart"},{False,True,Best}}]}
},Alignment->Right,Spacings->2]
]]

SSSInteractiveDisplay::usage="SSSInteractiveDisplay provides an interactive display of the current SSS and causal network, with controls for easy adjustment of common options.  Click the button to create a SSSDisplay object with the selected options.";

(* SSS: The default workhorse function to build and display SSSs and their causal networks.  (After use, they can be used and redisplayed without rebuilding, using SSSDisplay, etc.) *)      
                  
SSS[rs:{___Rule},init_String,n_Integer?Positive,opts___] := 
If[SSSInitialize[rs,init], 
SSSEvolve[n-1,Sequence@@FilterRules[{opts},Options[SSSEvolve]]]; 
SSSDisplay[Sequence@@FilterRules[{opts},Options[SSSDisplay]]]
];

Options[SSS]=Join[Options[SSSEvolve],Options[SSSDisplay]];
SyntaxInformation[SSS]={"ArgumentsPattern"->{_,_,_,OptionsPattern[]}};
SSS::usage="SSS[\!\(\*StyleBox[\(\*StyleBox[\"rule\",FontSlant->\"Italic\"]set\)]\)\!\(\*StyleBox[\",\",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\" \",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\"init\",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\",\",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\" \",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\"n\",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\",\",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\" \",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\"opts\",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\"]\",FontSlant->\"Italic\"]\)\!\(\*StyleBox[\" \",FontSlant->\"Italic\"]\)creates and displays a sequential substitution system (SSS) and its causal network, using \!\(\*StyleBox[\"ruleset\",FontSlant->\"Italic\"]\) starting with the state \!\(\*StyleBox[\"init\",FontSlant->\"Italic\"]\) (using string notation), allowing the SSS to evolve for \!\(\*StyleBox[\"n\",FontSlant->\"Italic\"]\) steps.  Use the option EarlyReturn to give/deny permission to quit early if the SSS can be identified as dead or (pseudo-)repeating.)  Any other options given are passed on to SSSDisplay.

(After creation the current SSS can be displayed or manipulated without rebuilding, using SSSDisplay, SSSAnimate, or directly using the global variables $SSSRuleSet, $SSSEvolution and $SSSNet.)";

(* SSSAnimate, SSSAnimateByDistance *)

SSSAnimate := Module[{g}, 
g=SSSDisplay[VertexLabeling->True,NetMethod->{GraphPlot,NoSSS}][[1,1,1,1]];
Animate[
Graphics[g/.
Text[Framed[n,_List],node_]:>
Text[Framed[n,List[Rule[Background,Green],Rule[FrameStyle,Black],Rule[FrameMargins,Automatic]],RoundingRadius->10],
node] /.
Text[Framed[m:Except[n,_Integer],l_List],node_] :>Point[node],ImageSize->Large
],
{n,1,Length[$SSSEvolution],1,Appearance->"Labeled",AnimationRate->2,AnimationRunning->True}]]

SSSAnimateByDistance := Module[{g,mx=Length[DistanceTally]},
g=SSSDisplay[UseDistances->True,VertexLabeling->True,NetMethod->{GraphPlot,NoSSS}][[1,1,1,1]];
Animate[
Graphics[
g/.Text[Framed[Subscript[n,s_Style],_List],node_]:>
Text[Framed[Subscript[n,s],List[Rule[Background,Green],Rule[FrameStyle,Black],Rule[FrameMargins,Automatic]],RoundingRadius->10],
node]/.
Text[Framed[Subscript[m:Except[n,_Integer],s_Style],_List],node_] :>Point[node],ImageSize->Large
],
{n,1,mx,1,Appearance->"Labeled",AnimationRate->1,AnimationRunning->True}]]

(* SSSInteractiveHistory *)

 SSSInteractiveHistory := With[{mxmx=Length[$SSSEvolution]},
Manipulate[
mn=Min[Max[1,mn],mxmx];
mx=Min[Max[1,mn,mx],mxmx];
Grid@Transpose[{Range[mn,mx],If[showEvolution,$SSSEvolution[[mn;;mx]],Table["",{i,mn,mx}]],Append[$SSSHistory,""][[mn;;mx]],Append[$SSSMatchLengthHistory,""][[mn;;mx]]}],
Grid[{{Control[{{mn,1,"Min"},1,mxmx,1,Appearance->"Labeled"}],Control[{{mx,mxmx,"Max"},1,mxmx,1,Appearance->"Labeled"}],
Control[{showEvolution,{False,True}}],"Current Verdict: "<>$SSSVerdict<>", {start,interval} = "<>ToString[{$SSSRepetitionStart,$SSSRepetitionInterval}]}
},Alignment->Right,Spacings->2]
]];

SSSInteractiveHistory::usage="SSSInteractiveHistory provides an interactive display of the current SSS and its history, with controls for easy adjustment of the region to display.";

(* Initial string for a given ruleset: SSSInitialState (defines & uses nextLyndon, deBruijn) *)

nextLyndon[k_,n_,w_List] := Module[{x=Table[0,{n}],l=Length[w],lastchar=n},
x=w[[Mod[Range[1,n],l,1]]];   (* permute the digits appropriately *)
While[lastchar>=0 && x[[lastchar]]==k-1,lastchar--];  (* back up past end trash *)
If[lastchar==0,
{}, (* nothing left, we're done *)
x[[lastchar]]++;x[[;;lastchar]]  (* increment last digit, return appropriate part *)
]];
deBruijn[k_,n_] := deBruijn[k,n]=Module[{s,d=Divisors[n]},
s=NestWhileList[nextLyndon[k,n,#]&,{0},#!={}&];
Join @@ Select[s,MemberQ[d,Length[#]]&]
];

SSSInitialState[r_Rule] := Module[{lhs,k,n,chars,s,len},
lhs=First[r];
If[lhs=="",lhs="A"];
chars=Union[Characters [lhs]];
k=Length[chars];
n=StringLength[lhs];
s=deBruijn[k,n][[Mod[Range[k^n+n-1],k^n,1]]];
StringJoin[s /. Thread[Range[k]-1->chars]]
];

SSSInitialState[rs:{Rule[_,_]...}] := Module[{lhs=First /@ rs,runs,bigruns,full=StringJoin[Union[SSSInitialState /@ rs]],dels},
runs = Union[Flatten[StringJoin /@ Split[Characters[#]]& /@ lhs]]; (* runs of same character existing in lhs *)
bigruns=Last /@ SplitBy[runs,StringTake[#,1]&]; (* biggest run of each character *)
dels=StringJoin[#,StringTake[#,1]]& /@ bigruns; (* next bigger for each character *)
FixedPoint[StringReplace[#,Thread[dels->bigruns]]&,full]  (* keep replacing the too big runs by the max allowed size, stop when no futher change *)
];

(* Universal Enumeration of SSS RuleSets:  from/toOldRuleSetRank, UniqueRuleSetQ *)

fromOldRuleSetRank[iplusflag_Integer/;iplusflag>0] := Module[{i,extraflag,n,j,quaternaryDigits,numberOfEOS,chopPos,extra,ans={{1}},strings,ruleset},
extraflag = OddQ[iplusflag];
i=Quotient[iplusflag+1,2];       (* offset so i can start at 1 instead of 0 *)
n=Floor[Log[4,3 i-2]];
j=i-(4^n+2)/3;
quaternaryDigits=IntegerDigits[j,4,n];
Scan[
Switch[#,
0 ,ans=Join[ans,{{},{1}}] ,
1,AppendTo[ans,{1}],
2,AppendTo[ans[[-1]],1],
3,ans[[-1]][[-1]]++
]&,
quaternaryDigits];
strings=StringJoin @@@ (FromCharacterWeights /@ ans);
If[extraflag,strings=Join[Most[strings],{"",Last[strings]}]];
If[OddQ[Length[strings]],strings=AppendTo[strings,""]];
Rule @@@ Partition[strings,2,2]
];

toOldRuleSetRank[rs_List] := Module[{rl,wl,w,code="",extrabit=1},
rl=Flatten[List @@@ rs];
If[Last[rl]=="",rl=Most[rl]]; (* drop ultimate empty string, if needed *)
If[Length[rl]>1 && rl[[-2]]=="",extrabit=0;rl=Drop[rl,{-2}]]; 
(* remove "\[Rule]" and drop penultimate empty string, if needed *)
(* wl=1+fromAlpha /@ rl; *)
wl=ToCharacterWeights /@ rl; (* to lists of lists of numbers "A"\[Rule]1, etc., but ""\[Rule]{}, not 0 *)
wl=wl /. 0->{};
w=Total[Flatten[wl]]; (* weight of this rule set *)
While[wl!={{1}},
If[wl[[-1]][[-1]]>1, code="3"<>code; wl[[-1]][[-1]]--,
If[wl[[-1]][[-1]]==1 && Length[wl[[-1]]]>1,  code="2"<>code; wl[[-1]]=Most[wl[[-1]]],
If[Length[wl]>=2 && wl[[-2;;]]=={{},{1}}, code="0"<>code; wl=Drop[wl,-2],
If[wl[[-1]]=={1},  code="1"<>code; wl=Drop[wl,-1]]]]]];
2(FromDigits[code,4]+(4^(w-1)+2)/3)+extrabit-1](* add number of rulesets of smaller weights to reconstructed quaternary code, leftshift and add extrabit at the end, subtract 1 so we can start at 1 instead of at 2 (2 \[Times] basic ruleset number, which has a minimum of 1) *)

UniqueRuleSetQ[n_Integer] := (n==toOldRuleSetRank[fromOldRuleSetRank[n]]);

fromReducedRank[i_Integer/;i>0] := Module[{n,j,quinaryDigits,numberOfEOS,chopPos,extra,ans={{1}},strings,ruleset},
n=Floor[Log[5,4i-3]];
j=i-(5^n+3)/4;
quinaryDigits=IntegerDigits[j,5,n];  (* the base-5 code for this ruleset will contain n digits, the ruleset weight is n+1 *)
Scan[
Switch[#,
0 ,ans=Join[ans,{{},{},{1}}] ,
1,ans=Join[ans,{{},{1}}] ,
2,AppendTo[ans,{1}],
3,AppendTo[ans[[-1]],1],
4,ans[[-1]][[-1]]++
]&,
(* Print@quinaryDigits; *)
quinaryDigits];
strings=StringJoin @@@ (FromCharacterWeights /@ ans);
If[OddQ[Length[strings]],strings=AppendTo[strings,""]];
Rule @@@ Partition[strings,2,2]
];

fromReducedRankShowSteps[i_Integer/;i>0] := Module[{n,j,quinaryDigits,numberOfEOS,chopPos,extra,ans={{1}},strings,ruleset},
n=Floor[Log[5,4i-3]];
j=i-(5^n+3)/4;
quinaryDigits=IntegerDigits[j,5,n];
Scan[
Switch[#,
0 ,ans=Join[ans,{{},{},{1}}] ,
1,ans=Join[ans,{{},{1}}] ,
2,AppendTo[ans,{1}],
3,AppendTo[ans[[-1]],1],
4,ans[[-1]][[-1]]++
]&,
quinaryDigits];
strings=StringJoin @@@ (FromCharacterWeights /@ ans);
If[OddQ[Length[strings]],strings=AppendTo[strings,""]];
{i,":"," w="<>ToString[n+1]<>", offset=(",Superscript[5,n]+3,")/4, reduced = "<>ToString[j]<>" = ",Subscript[Row@quinaryDigits,5]," => ",Rule @@@ Partition[strings,2,2]} 
];

toReducedRank[rs_List] := Module[{rl,wl,w,code=""},
rl=Flatten[List @@@ rs];
If[Last[rl]=="",rl=Most[rl]]; (* drop ultimate empty string, if needed *)
(* wl=1+fromAlpha /@ rl; *)
wl=ToCharacterWeights /@ rl; (* to lists of lists of numbers "A"\[Rule]1, etc., but ""\[Rule]{}, not 0 *)
wl=wl /. 0->{};
w=Total[Flatten[wl]]; (* weight of this rule set *)
While[wl!={{1}},
Which[
wl[[-1]][[-1]]>1, code="4"<>code; wl[[-1]][[-1]]--,
wl[[-1]][[-1]]==1 && Length[wl[[-1]]]>1,  code="3"<>code; wl[[-1]]=Most[wl[[-1]]],
Length[wl]>=3 && wl[[-3;;]]=={{},{},{1}}, code="0"<>code; wl=Drop[wl,-3],
Length[wl]>=2 && wl[[-2;;]]=={{},{1}}, code="1"<>code; wl=Drop[wl,-2],
wl[[-1]]=={1},  code="2"<>code; wl=Drop[wl,-1]
]
];
(FromDigits[code,5]+(5^(w-1)+3)/4)  (* add number of rulesets of smaller weights to reconstructed quinary code *)
];

fromReducedRankQuinaryCode[s_String] := Module[{n,j,quinaryDigits,numberOfEOS,chopPos,extra,ans={{1}},strings,ruleset},
quinaryDigits=ToCharacterCode[s]-48;
Scan[
Switch[#,
0 ,ans=Join[ans,{{},{},{1}}] ,
1,ans=Join[ans,{{},{1}}] ,
2,AppendTo[ans,{1}],
3,AppendTo[ans[[-1]],1],
4,ans[[-1]][[-1]]++
]&,
(* Print@quinaryDigits; *)
quinaryDigits];
strings=StringJoin @@@ (FromCharacterWeights /@ ans);
If[OddQ[Length[strings]],strings=AppendTo[strings,""]];
Rule @@@ Partition[strings,2,2]
];

toReducedRankQuinaryCode[rs_List] := Module[{rl,wl,w,code=""},
rl=Flatten[List @@@ rs];
If[Last[rl]=="",rl=Most[rl]]; (* drop ultimate empty string, if needed *)
(* wl=1+fromAlpha /@ rl; *)
wl=ToCharacterWeights /@ rl; (* to lists of lists of numbers "A"\[Rule]1, etc., but ""\[Rule]{}, not 0 *)
wl=wl /. 0->{};
w=Total[Flatten[wl]]; (* weight of this rule set *)
While[wl!={{1}},
Which[
wl[[-1]][[-1]]>1, code="4"<>code; wl[[-1]][[-1]]--,
wl[[-1]][[-1]]==1 && Length[wl[[-1]]]>1,  code="3"<>code; wl[[-1]]=Most[wl[[-1]]],
Length[wl]>=3 && wl[[-3;;]]=={{},{},{1}}, code="0"<>code; wl=Drop[wl,-3],
Length[wl]>=2 && wl[[-2;;]]=={{},{1}}, code="1"<>code; wl=Drop[wl,-2],
wl[[-1]]=={1},  code="2"<>code; wl=Drop[wl,-1]
]
];
code
];

(* from/toGeneralizedRank (& fromGeneralizedRankShowSteps), overload SSS[n, steps, opts] *)

fromGeneralizedRank[i_Integer/;i>0] := Module[{n,j,bit,quinaryDigits,numberOfEOS,chopPos,ans,strings,ruleset},
n=Floor[Log[5,10i-5]];
j=i-(5^n+5)/10;
{bit,j}=QuotientRemainder[j,5^(n-1)];
quinaryDigits=IntegerDigits[j,5,n-1];
ans=Switch[bit,
0,{{},{1}},
1,{{1}}
];
Scan[
Switch[#,
0 ,ans=Join[ans,{{},{},{1}}] ,
1,ans=Join[ans,{{},{1}}] ,
2,AppendTo[ans,{1}],
3,AppendTo[ans[[-1]],1],
4,ans[[-1]][[-1]]++
]&,
quinaryDigits];
strings=StringJoin @@@ (FromCharacterWeights /@ ans);
If[OddQ[Length[strings]],strings=AppendTo[strings,""]];
(* {"i: ",i," n:",n," j: ",i-(5^n+5)/10,{bit,j},Flatten[{bit,quinaryDigits}],Rule @@@ Partition[strings,2,2]} *)
 Rule @@@ Partition[strings,2,2]
];
      
fromGeneralizedRankShowSteps[i_Integer/;i>0] := Module[{n,j,bit,quinaryDigits,numberOfEOS,chopPos,ans,strings,ruleset},
n=Floor[Log[5,10i-5]];
j=i-(5^n+5)/10;
{bit,j}=QuotientRemainder[j,5^(n-1)];
quinaryDigits=IntegerDigits[j,5,n-1];
ans=Switch[bit,
0,{{},{1}},
1,{{1}}
];
Scan[
Switch[#,
0 ,ans=Join[ans,{{},{},{1}}] ,
1,ans=Join[ans,{{},{1}}] ,
2,AppendTo[ans,{1}],
3,AppendTo[ans[[-1]],1],
4,ans[[-1]][[-1]]++
]&,
quinaryDigits];
strings=StringJoin @@@ (FromCharacterWeights /@ ans);
If[OddQ[Length[strings]],strings=AppendTo[strings,""]];
{i,":"," w="<>ToString[n]<>", offset=(",Superscript[5,n]+5,")/10, reduced = "<>ToString[i-(5^n+5)/10]<>" = ",Subscript[bit,2],Subscript[Row@quinaryDigits,5]," => ",Rule @@@ Partition[strings,2,2]} 
 ];

toGeneralizedRank[rs_List] := Module[{rl,wl,w,bit,quincode=""},
rl=Flatten[List @@@ rs];
If[Last[rl]=="",rl=Most[rl]]; (* drop ultimate empty string, if needed *)
(* wl=1+fromAlpha /@ rl; *)
wl=ToCharacterWeights /@ rl; (* to lists of lists of numbers "A"\[Rule]1, etc., but ""\[Rule]{}, not 0 *)
wl=wl /. 0->{};
w=Total[Flatten[wl]]; (* weight of this rule set *)
While[wl!={{1}} && wl!={{},{1}},
Which[
wl[[-1]][[-1]]>1, quincode="4"<>quincode; wl[[-1]][[-1]]--,
wl[[-1]][[-1]]==1 && Length[wl[[-1]]]>1,  quincode="3"<>quincode; wl[[-1]]=Most[wl[[-1]]],
Length[wl]>=3 && wl[[-3;;]]=={{},{},{1}}, quincode="0"<>quincode; wl=Drop[wl,-3],
Length[wl]>=2 && wl[[-2;;]]=={{},{1}}, quincode="1"<>quincode; wl=Drop[wl,-2],
wl[[-1]]=={1},  quincode="2"<>quincode; wl=Drop[wl,-1]
]
];
Switch[wl,
{{},{1}}, bit=0,
{{1}} ,bit=1
];
(* {"w:",w,(ToCharacterWeights /@ rl) /. 0\[Rule]{},Row@{bit,"\[Times]", 5^(w-1)," + ",quincode," (",FromDigits[quincode,5],") + ",(5^w+5)/10}," => ",bit\[Times]5^(w-1)+FromDigits[quincode,5]+(5^w+5)/10} *)
bit*5^(w-1)+FromDigits[quincode,5]+(5^w+5)/10
];

SSS[index_Integer,steps_Integer,opts___] := SSS[#,SSSInitialState[#],steps,opts]&[fromGeneralizedRank[index]]
      
 End[]
 
 (* is this public? *)
 
 SSSEvolve[x___] := SSS`Private`SSSEvolve[x];
 SSS[x___] := SSS`Private`SSS[x];
 SSSDisplay[x___] := SSS`Private`SSSDisplay[x];

 SSSInteractiveDisplay[x___] := SSS`Private`SSSInteractiveDisplay[x];
 SSSAnimate[x___] := SSS`Private`SSSAnimate[x];
 SSSAnimateByDistance[x___] := SSS`Private`SSSAnimateByDistance[x];
 SSSInteractiveHistory[x___] := SSS`Private`SSSInteractiveHistory[x];
 SSSInitialState[x___] := SSS`Private`SSSInitialState[x];
 fromReducedRank[x___] := SSS`Private`fromReducedRank[x];
 fromReducedRankShowSteps[x___] := SSS`Private`fromReducedRankShowSteps[x];
 toReducedRank[x___] := SSS`Private`toReducedRank[x];
 fromReducedRankQuinaryCode[x___] := SSS`Private`fromReducedRankQuinaryCode[x];
 toReducedRankQuinaryCode[x___] := SSS`Private`toReducedRankQuinaryCode[x];
 
 EndPackage[]
 
