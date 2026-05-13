kg-Elections version 0.01
=========================

This was a quick cheap-and-easy way to set up anonymous voting for Zoom
meetings when we moved online at the beginning of the pandemic.

When you create the meeting you specify the number of voters. Each person
joining the voting gets a private key (UUID). When all the people have voted
you can ask on Zoom, "did everybody complete their vote?", which guards against
somebody voting twice or sneaking in to the voting or whatever, and if that
round of ballots was compromised you can just create a new meeting. Each voter
can refresh their screen to see the progress of the voting, and when all the
votes are in for that meeting they'll see the results.

![Meeting Creation](/doc/elections-1.png)

![Initial Voting Page](/doc/elections-2.png)

![Vote Cast Page](/doc/elections-3.png)

![Voting Complete Page](/doc/elections-4.png)

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

COPYRIGHT AND LICENCE

Put the correct copyright and licence information here.

Copyright (C) 2020 by Kevin M. Goess <cpan@goess.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.3 or,
at your option, any later version of Perl 5 you may have available.


