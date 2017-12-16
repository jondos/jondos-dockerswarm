#!/usr/bin/perl
# aplog-anon -- Real-Time-Anonymisierung von Apache-Log-Daten
# Copyright (C) 2003 by Z E N D A S, Universität Stuttgart.
#
# ZENDAS bemüht sich, die Richtigkeit und Funktionsfähigkeit der  
# bereitgestellten Skripte zu gewährleisten. Wir können jedoch nicht dafür 
# einstehen, dass die Skripte auch auf Ihren Systemen auf Anhieb ohne  
# Probleme laufen oder Ihr Server nach Installation der Skripte zusätzlichen 
# Konfigurationsaufwand erfordert und/oder zeitweise nicht einsetzbar ist.
# ZENDAS erklärt sich ausdrücklich für Schäden jeglicher Art, die
# Ihnen, Ihrem Computer oder jeglicher dritten Person oder Sache durch die
# Nutzung oder den Missbrauch dieser Skripte entstehen könnten,
# nicht verantwortlich. Sie nutzen diese Skripte ausdrücklich auf eigenes
# Risiko.
#
#
# Die Anonymisierung dier Client-Adressen wird auf /16er-Netzmasken
# durchgeführt. Eine andere Möglichkeit wären /24er-Netzmasken, aber
# dadurch ist nicht völlig sichergestellt, daß der Personenbezug
# verloren geht.  Zusätzlich wird der Referer-URL beim ersten "?"
# abgeschnitten.
#
# In der allgemeinen Apache-Konfiguration ist folgende Zeile einzufügen:
#
# LogFormat "%a - - %t \"%r\" %>s %b \"%{Referer}i\"" combined
#
# In der Konfiguration für virtuelle Server wird das Logging wie folgt
# aktiviert:
#
# ErrorLog "|/path/to/aplog-anon /path/to/error_log"
# CustomLog "|/path/to/aplog-anon /path/to/access_log" combined
#
# Änderungen an den Skripten für die Log-Rotation sind üblicherweise
# nicht erforderlich. Das Logging über eine Pipe erfordert ein paar
# zusätzliche Context Switches; dies sollte aber nur unter absolutem
# Hochlastbetrieb ein Problem darstellen; das Anonymsieren
# funktioniert auf Hardware aus dem Jahr 2002 auch bei mehreren
# Requests pro Sekunde ohne Probleme.
#
# Vorsicht: aplog-anon schreibt typischerweise die Log-Datei mit
# root-Rechten.

use strict;
use warnings;

use IO::Handle;

if (@ARGV != 1) {
    exit 1;
}

my $LOG;
open $LOG, ">>$ARGV[0]";

# Daten sofort in die Zieldatei schreiben, ohne Pufferung auf Perl-Seite.
$LOG->autoflush(1);

while (my $Line = <STDIN>) {
    chomp $Line;

    # Das ist eine krude Annäherung an einen richtigen Parser. Sie
    # erwischt im Prinzip alles, was gültige Requests sind. Vom
    # Referer wird alles nach dem ersten "?" weggeschnitten, um das
    # Logging einer Session-ID zu vermeiden.

    # Der erste Fall behandelt Fehlermeldungen, die eine andere Syntax
    # haben.
    if ($Line =~ /^\[.*/) {
        $Line =~ s/^(.*?\[client \d+\.\d+)\.\d+\.\d+(\].*)/$1.0.0$2/;
    } else {
        $Line =~ s/^(\d+\.\d+)\.\d+\.\d+ (.*" (?:\d+|-) (?:\d+|-) "[^?]*).*/$1.0.0 $2\"/;
        $Line =~ s/""$/\"/;
    }

    print $LOG "$Line\n";
}

######################################################################