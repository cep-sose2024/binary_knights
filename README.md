
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
  <li><a href="#enitlement_zuweisen">Was passiert, wenn man der App / Executable Entitlements zuweist?</a></li>
  <li><a href="#loesungen">Gibt es Lösungsansätze?</a></li>
  <li><a href="#commands">Benötigte Commands</a></li>
</ul>

<h2 id="entstehung">Entstehung</h2>
<p>Bei diesem Github-Repo handelt es sich um die Swift-Rust-Brücke von <a>chinedufn</a> orientiert am Beispiel <a href="https://github.com/chinedufn/swift-bridge/tree/ef01d21001914b79e0384627535098e15f87f096/examples/rust-binary-calls-swift-package">rust-binary-calls-swift-package</a>.
<br>
Im Ordner `swift-library` wurde unserer SecureEnclaveManager-Code, aus unserer <b>main-Branche</b>, implementiert.
</p>


<section class="second_section">
<h2 id="code_ausfuehren">Wie kann ich den Code ausführen?</h2>
<p>Dadurch, dass es sich hierbei um eine Swift-Rust-Brücke handelt, geschieht der Zugriff auf den Swift-Code hauptsächlich über Rust. 
</p>

<p>In der Datei `swift-library --> main.rs` kann man ein Beispiel sehen, wie man mit Rust sich ein KeyPair (Privater + Öffentlicher Schlüssel) in der Secure-Enclave von Apple generieren lassen kann. Dafür muss man die `main.rs` einmal ausführen lassen.
<br>
<br>
Achtung!!!: Es kann sein, dass der Code nicht beim ersten Mal sofort ausgeführt werden kann, weil beim vorherigen Build bei einem anderen Entwickler andere Paths gesetzt wurden. Einmal bitte <a href="#cargoclean">cargo clean</a> ausführen und die ".build"-Dateien löschen. 
</p>
</section>

<h2 id="problem">Gibt es Probleme beim Ausführen des Codes?</h2>
<p>
Bei der Ausführung der `main.rs` kommt eine Fehlermeldung: "<label style="color: red;>">[...] Domain=NSOSStatusErrorDomain Code-34018 [...]</label>"
<br>
<br>
Das ist eine Fehlermeldung, die direkt vom MacOS-Betriebssystem kommt. Nach einer ausgiebigen Recherche und dem bereits laufenden Prototypen (mit Xcode + Swift) ist es mit einer <b>sehr hohen Wahrscheinlichkeit die Zugriffskontrolle von Apple</b>, die den Fehlercode provoziert.<br>

<a href="https://forums.developer.apple.com/forums/thread/728150">Quelle: Link zum Apple Developer Forum</a>
</p>
<hr>


<section class="second_section">
<h3 id="zugriffskontrolle">Wie kann man die Zugriffskontrolle bestehen?</h3>
<p><u>Nach bisherigen Wissenstand:</u><br>
Bei iOS / MacOS-Apps kann man anhand von gewissen <a href="https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AboutEntitlements.html">".entitlements"</a> die Zugriffsrechte der App oder einer Executable (Mach-O-Datei) setzten. In diesen Entitlements kann gesetzt werden, welche Zugriffsrechte die App / Executable hat. 
<br>
In unserem Fall, wären es wahrscheinlich die Zugriffsrechte auf die Secure Enlcave / Keychain-Sharing-Service, die im Entitlement gesetzt werden müssen.
<br>
Des Weiteren muss wahrscheinlich auch ein Developer-Zertifikat an die App / Executable mitgegeben werden.
<br><br>
Um die Entitlements und das Developer-Zertifkat einer App / Executable mitzugeben, kann man einen vorgefertigen Command <a href="#codesign_set">"codesign"</a> unter dem Kapitel "<a href="#commands"><b>Benötige Commands</b></a>" finden. Bitte ersetzt die Elemente in den eckigen Klammern "[...]" mit euren angepassten Daten. 
</p>
<hr>
</section>


<h3 id="dev_zertifikat">Wo kann ich die Kennung meines Developer-Zertifikat finden?</h3>
Tastenkombination "[cmd] + Leertaste" drücken --> "Schlüsselbundverwaltung" eingeben --> "Schlüsselbundverwaltung öffnen" drücken -->  "Meine Zertifikate" / Oder manuell suchen nach <b>"Apple Development: [E-Mail] ([Kennung])"</b> suchen.
<hr>

<section class="second_section">
<h3 id="entitlements">Wie kann ein Entitlement aussehen?</h3>
Entitlements sind in einem XML-Formatt aufgebaut und können, sowohl mit einem Texteditor, sowie einem Programm von Apple selbst angepasst werden.
<br>
Um das Programm von Apple zu benutzen muss das Entitlement die Endung ".entitlement" besitzen und erleichtert es die richtige Formatierung und von Apple vordefinierte Zugriffsmöglichkeiten zu setzen.
<br> 
Welcher Content in das Entitlement kommt muss vom Entwickler(-Team) selbst bestimmt und eingefügt werden. Im Internet, sowie auch auf der <a href="https://developer.apple.com/documentation/bundleresources/entitlements">Apple-Entitlement-Website</a>. 
</section>

<section class="second_section" style="background-color: #7e090057">
<h2 id="enitlement_zuweisen">Was passiert, wenn man der App / Executable Entitlements zuweist?</h2>
<p>
Unter "swift-library_and_rust" --> "target" --> "debug" kann man die Executable (Macho-O) finden und dieser Datei die Entitlements und das Developer-Zertifikat zuweisen. Nach dem dranknüpfen der Entitlements + Developer-Zertifikats startet man die Executable und es kommt sofort zum Absturz der Shell mit der Fehlermeldung "<label style="color: red;">zsh: killed</label>". 

<label>Folgende Gründe kann das Abstürzen der Shell haben: </label>
<ol>
  <li>Die Entitlements sind falsch gesetzt oder ungültig.</li>
  <li>Der Fakt, dass die Metohden aus der `main.rs` gerufen werden und es aus einer Rust-Instanz passiert. Welche nicht nativ von Apple unterstütz wird.</li>
</ol>
</p>
</section>

<section class="second_section" style="background-color: #00810d21">
<h2 id="loesungen">Gibt es Lösungsansätze?</h2>
Für Punkt 1: <br>
Es wird eine reine Mach-O Datei erstellt, die in der nativen Apple-Programmiersprache "Swift" geschrieben ist. Diese erhält dieselben Entitlements + Apple Developer Zertifkat, wie das Executsable von Rust. Sollte diese Datei ebenso nicht starten können und dieselbe Fehlermeldung "<label style="color: red;">zsh: killed</label>" erhalten --> Entitlements sind schuld und müssen überarbeitet werden. Evtl. muss wieder Kontakt mit j&s soft aufgenommen werden.<br><br>
Für Punkt 2: <br>
Man überprüft mit gewissen Debuger-Tools, wie "gdb" und "lldb", was in dem Prozess passiert, wenn die Rust-Executable ausgeführt wird. Dadurch kann man den Fehler besser eingrenzen  und beheben. 
<br>
<br>
</section>

<section class="second_section" style="background-color: #0059813d">
<h2 id="commands">Benötigte Commands</h2>
Folgende Commands können hilfreich sein in der Benutzung des Github-Repos: 
<h3 id="cargobuild"><i>cargo build</i></h3>
<ul>
  <li>Diese Command wird in die Befehlszeile / cmd / Terminal eingegeben, um sich die Executable generieren zu lassen. Die Executable befindet sich dann im Verzeichnis: "swift-library_and_rust" --> "target" --> "debug"
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

<h3 id="codesign_set"><i>codesign -f -s "[Kennung des Apple Zertifikats]" --entitlements "[Dateiname].entitlements" [Name vom Executable]</i></h3>
<ul>
  <li>Weist der App / Exetuable die Entitlements + Apple-Developer-Zertikat</li>
  <li>Beim Apple-Developer-Zertifikat reicht wohl schon alleine die Kennung / Name des Zertifikats. Kann man aber auch das richtige Apple-Zertifkat aus der Schlüsselbundverwaltung exportieren und über die Eingabe eines Dateipfades zuweisen.</li>
  <li><b>Beispiel:</b> <br><i>codesign -f -s "Apple Development: dreimer03@googlemail.com (XXXXXXX)" --entitlements "binaryknights.entitlements" rustbinary-calls-swift-package</i></li>
</ul>

<h3 id="codesign_display"><i>codesign -d --entitlements - [Dateiname vom Exetuable / App]</i></h3>
<ul>
  <li>Zeigt die gesetzten Entitlements auf</li>
</ul>
</section>


