%{
   configs: [
     %{
       name: "default",
       strict: true,
       checks: %{
         extra: [
           {Credo.Check.Readability.LargeNumbers, only_greater_than: 32_700},
           {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 12},
           {Credo.Check.Refactor.Nesting, max_nesting: 3}
         ]
       }
     }
   ]
 }
