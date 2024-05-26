
<!-- <style>
  .second_section{
    background-color: #272727; 
    border-radius: 10px; 
    padding-top: 2px;
    padding-bottom: 2px;  
    margin-top: 10px; 
  }
</style> -->

<p align=center>
    <a href="https://github.com/cep-sose2024/binary_knights/" target="_blank"><img src="documentation/pictures/logoBlack.png" style="width:20%;"></a>
</p>

<h1>Swift-Library in Rust</h1>
<p style="font-size:30px;">Gliederung</p>
<ul>
  <li><a href="#entstehung">Entstehung</a></li>
  <li><a href="#code_ausfuehren">Wie kann ich den Code ausführen? </a></li>
  <li><a href="#problem">Gibt es Probleme beim Ausführen des Codes?</a></li>
  <li><a href="#zugriffskontrolle">Wie kann man die Zugriffskontrolle bestehen?</a></li>
  <li><a href="#dev_zertifikat">Wo kann ich die Kennung meines Developer-Zertifikat finden?</a></li>
  <li><a href="#entitlements">Wie kann ein Entitlement aussehen?</a></li>
  <!-- <li><a href="#enitlement_zuweisen">Was passiert, wenn man der App / Executable Entitlements zuweist?</a></li> -->
  <!-- <li><a href="#loesungen">Gibt es Lösungsansätze?</a></li> -->
  <li><a href="#commands">Benötigte Commands</a></li>
</ul>

<h2 id="entstehung">Entstehung</h2>
<p>Bei diesem Github-Repo handelt es sich um die Swift-Rust-Brücke von <a>chinedufn</a> orientiert am Beispiel <a href="https://github.com/chinedufn/swift-bridge/tree/ef01d21001914b79e0384627535098e15f87f096/examples/rust-binary-calls-swift-package">rust-binary-calls-swift-package</a>.
<br>
Im Ordner `swift-library` wurde unserer SecureEnclaveManager-Code, aus unserer aktuellen <b>main-Branche</b>, implementiert.
</p>


<section class="second_section">
<h2 id="code_ausfuehren">Wie kann ich den Code ausführen?</h2>
<p>Dadurch, dass es sich hierbei um eine Swift-Rust-Brücke handelt, geschieht der Zugriff auf den Swift-Code hauptsächlich über Rust. 
</p>

<p>In der Datei `swift-library --> main.rs` kann man ein Beispiel sehen, wie man mit Rust sich ein KeyPair (Privater + Öffentlicher Schlüssel) in der Secure-Enclave von Apple generieren lassen kann. Dafür muss man die `main.rs` einmal ausführen lassen.
<br>
<br>
Achtung!!! Es kann sein, dass der Code nicht beim ersten Mal sofort ausgeführt werden kann: 
<ul><li>Bei vorherigen Build können bestehende Konfigurationen von einem anderen System mitgegeben werde. Einmal bitte <a href="#cargoclean">cargo clean</a> ausführen und die ".build"-Dateien löschen. </li>
<li>
Da wir mit Entitlements arbeiten und diese manuell mit <a href="#">diesem Command</a> nach dem Build-Prozess an die Mach-O-Datei eingebunden werden, reicht es nicht immer mit <i>cargo run</i> das Programm auszuführen. Am besten die Mach-O-Datei im Finder selbst ausführen unter "swift-library_and_rust" --> "target" --> "debug". 
</li>
<ul>
</p>
</section>

<!-- <h2 id="problem">Gibt es Probleme beim Ausführen des Codes?</h2>
<p>
Bei der Ausführung der `main.rs` kommt eine Fehlermeldung: "<label style="color: red;>">[...] Domain=NSOSStatusErrorDomain Code-34018 [...]</label>"
<br>
<br>
Das ist eine Fehlermeldung, die direkt vom MacOS-Betriebssystem kommt. Nach einer ausgiebigen Recherche und dem bereits laufenden Prototypen (mit Xcode + Swift) ist es mit einer <b>sehr hohen Wahrscheinlichkeit die Zugriffskontrolle von Apple</b>, die den Fehlercode provoziert.<br>

<a href="https://forums.developer.apple.com/forums/thread/728150">Quelle: Link zum Apple Developer Forum</a>
</p> -->
<hr>


<section class="second_section">
<h3 id="zugriffskontrolle">Wie kann man die Zugriffskontrolle bestehen?</h3>
<p><u>Nach bisherigen Wissenstand:</u><br>
Bei iOS / MacOS-Apps kann man anhand von gewissen <a href="https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AboutEntitlements.html">".entitlements"</a> die Zugriffsrechte der App oder einer Executable (Mach-O-Datei) setzten. In diesen Entitlements kann gesetzt werden, welche Zugriffsrechte die App / Executable hat. 
<br>
In unserem Fall ist es hauptsächlich der Keychain-Sharing-Service, der in den Entitlements eingebaut werden muss, damit der Zugriff auf die Secure Enclave eines Macs möglich ist. 
<br>
Des Weiteren muss wahrscheinlich muss ein Bundle-Identifier / Application-Identifiert mitgegeben werden, sowie die Team-ID. 
Die Team-ID findet man in seinem Apple-Developer-Zertifikat
<br><br>
Um die Entitlements und das Developer-Zertifkat einer App / Executable mitzugeben, kann man einen vorgefertigen Command <a href="#codesign_set">"codesign"</a> unter dem Kapitel "<a href="#commands"><b>Benötige Commands</b></a>" finden. Bitte ersetzt die Elemente in den eckigen Klammern "[...]" mit euren angepassten Daten. 
</p>
<hr>
</section>


<h3 id="dev_zertifikat">Wo kann ich die Kennung meines Developer-Zertifikat finden?</h3>
Tastenkombination "[cmd] + Leertaste" drücken --> "Schlüsselbundverwaltung" eingeben --> "Schlüsselbundverwaltung öffnen" drücken -->  "Meine Zertifikate" / Oder manuell suchen nach <b>"Apple Development: [E-Mail] ([Kennung])"</b> suchen.
<br><br>
Desweiteren kann man <a href="#show_certificats">diesen Command</a> im Terminal eingeben und ebenso valide Zertifikate aufgezeigt kriegen, die auf dem System hinterlegt sind. 
<hr>

<section class="second_section">
<h3 id="entitlements">Wie kann ein Entitlement aussehen?</h3>
Entitlements sind in einem XML-Formatt aufgebaut und können, sowohl mit einem Texteditor, sowie einem Programm von Apple selbst angepasst werden.
<br>
Um das Programm von Apple zu benutzen muss das Entitlement die Endung ".entitlement" besitzen und erleichtert es die richtige Formatierung und von Apple vordefinierte Zugriffsmöglichkeiten zu setzen.
<br> 
Sollte keine Entitlement-Datei zu finden sein, kann trotzdem ein Executable / Mach-O-Datei welche besitzen. Dafür den Command <a href="#entitlements_display_xml">hier</a> benutzen um diese auszulesen. 
<br>
Welcher Content in das Entitlement kommt muss vom Entwickler(-Team) selbst bestimmt und eingefügt werden. Im Internet, sowie auch auf der <a href="https://developer.apple.com/documentation/bundleresources/entitlements">Apple-Entitlement-Website</a>. 
</section>

<section class="second_section" style="background-color: #0059813d">
<h2 id="commands">Benötigte Commands</h2>
Folgende Commands können hilfreich sein in der Benutzung des Github-Repos: 
<h3 id="cargobuild"><i>cargo build</i></h3>
<ul>
  <li>Diese Command wird in die Befehlszeile / cmd / Terminal eingegeben, um sich die Executable- / Mach-O- Datei generieren zu lassen. Die Executable befindet sich dann im Verzeichnis: "swift-library_and_rust" --> "target" --> "debug"
  </li>
  <li>ACHTUNG!!! <ul>
                    <li>
                      Man muss sich mit der Befehlszeile / cmd / Terminal im Verzeichnis "swift-library_and_rust" befinden. Sonst können die Commands nicht ausgeführt werden!
                    </li>
                    <li>
                      Nach jedem Build wird immer eine neue Executable generiert, heißt: die Entitlements + Apple Developer Zertifikat muss immer neu der Executable zugewiesen werden.
                    </li>
                  </ul>
  </li>
</ul>

<h3><i>cargo run</i></h3>
<ul>
  <li>Es gelten dieselben Punkte wie bei "cargo build" und</li>
  <li>führt die `main.rs` aus</li>
</ul>

<h3 id="cargoclean">cargo clean</h3>
<ul>
  <li>Säubert alle Dateien, die im Build-Prozess erstellt wurden.</li>
  <li>Kann beispielsweise ausgeführt werden, wenn man Fehlermeldungen sieht, die einen Directory in einem Path versuchen auszuführen den es bei einem selbst nicht gibt. Passiert meistens, wenn man einen neuen Stand des Repos pulled und ein anderer Entwickler die Datein builden lässt.</li>
</ul>

<h3 id="codesign_set"><i>codesign -f -s "[Kennung / Hash des Apple Developer Zertifikats]" --entitlements "[Path zu der Entitlement-Datei]" -o runtime -i "[Bundle-Identifier]" "[Path zu der Executable- / Mach-O- Datei]"</i></h3>
<ul>
  <li>Weist der App / Exetuable die Entitlements + Apple-Developer-Zertikat</li>
  <li>Beim Apple-Developer-Zertifikat reicht wohl schon alleine die Kennung / Name / Hash des Zertifikats. Man kann aber auch das richtige Apple-Zertifkat aus der Schlüsselbundverwaltung exportieren und über die Eingabe eines Dateipfades zuweisen.</li>
  <li><b>Beispiel:</b> <br><i>codesign -f -s "Apple Development: dreimer03@googlemail.com (XXXXXXX)" --entitlements "binaryknights.entitlements" rustbinary-calls-swift-package</i></li>
  <li><i>codesign -f -s "5EF477686B05F574A5B6EFB478CCCC5FDDXXXXXX" --entitlements "../../binaryknights.entitlements" -o runtime -i "de.jssoft.-BinaryKnights-1.SecureEnclaveManager" "rust-binary-calls-swift-package"</i></li>
</ul>

<h3 id="show_certificats"><i>security find-identity -p codesigning -v</i></h3>
  <ul>
    <li>Zeigt den Hash oder die Kennung der validen Apple Developer Zertifikate an, die sich auf dem System befinden.</li>
    <li>Man kann für den Command<a href="codesign_set"> codesign </a>den Hash oder die Kennung verwenden</li>
    <li>Beispiel für eine Ausgabe:
    <br>
    <i>"1) 5EF477686B05F574A5B6EFB478CCCC5FDDXXXXX "Apple Development: dreimer03@googlemail.com (M995YNXXXX)"
     1 valid identities found"</i>
    </li>
  </ul>

  <h3><i>codesign -d -vvv [Dateiname vom Executable]</i></h3>
  <ul>
    <li>Zeigt auf, welches Developer-Team der Datei zugewiesen wurde, mit welchem Zertifikat die Datei signiert wurde und welche Zertifizierungsstelle die Gültigkeit des Zertikates verwaltet.</li>
  </ul>

<h3 id="entitlements_display"><i>codesign -d --entitlements - [Dateiname vom Executable / App]</i></h3>
<ul>
  <li>Zeigt die gesetzten Entitlements auf</li>
</ul>

<h3 id="entitlements_display_xml"><i>codesign -d --entitlements - --xml "binaryknights" | plutil -convert xml1 -o - -</i></h3>
<ul>
  <li>Zeigt die gesetzten Entitlements im XML-Format auf</li>
</ul>
</section>


