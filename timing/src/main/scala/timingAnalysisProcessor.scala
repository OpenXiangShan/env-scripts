package timing

import scala.math._
import scala.util._
import scala.io.Source
import scala.util.matching.Regex
import scala.util.Using
import scala.util.Try
import scala._
import scala.collection.mutable
import java.io._
import java.util.Date
import scala.language.postfixOps
import sys.process._
import sys._

class TimingAnalysisParser(val cycle: Double) extends FileIOUtils {
    val regGroupPattern = "\"(.*)\".*End_Path_Delay = (\\d+\\.\\d+) .*Start_Path_Delay = (\\d+\\.\\d+) ".r.unanchored
    type Delays = Tuple2[Double, Double]
    type Path = Tuple2[String, Delays]

    def getLines(s: scala.io.BufferedSource): Iterator[String] = s.getLines()
    def makeRecord(it: Iterator[String], m: List[Path] = List()): List[Path] = {
        def delayToDouble(d: String): Double = Try(d.toDouble).getOrElse(0.0)
        if (it.hasNext) {
            val next = it.next
            // println(next.getClass)
            next match {
                case regGroupPattern(name, endDelay, startDelay) => {
                    makeRecord(it, (name, (delayToDouble(endDelay), delayToDouble(startDelay))) :: m)
                }
                case _ => makeRecord(it, m)
            }
        } else {m}
    }

    def makeRecordFromFile(f: String): List[Path] = {
        readFile(f, s => makeRecord(getLines(s))).get
    }

    def totalDelayComp(p1: Path, p2: Path) = (p1._2._1 + p1._2._2) > (p2._2._1 + p2._2._2)
    def maxDelayComp(p1: Path, p2: Path) = max(p1._2._1, p1._2._2) > max(p2._2._1, p2._2._2)

    def totalDelayExceedsLimit(p: Path) = (p._2._1 + p._2._2) > 2*cycle
    def maxDelayExceedsLimit(p: Path) = p._2._1 > cycle || p._2._2 > cycle
    
    def sortWithTotalDelay(m: List[Path]) = m.sortWith(totalDelayComp).filter(totalDelayExceedsLimit)
    def sortWithMaxDelay(m: List[Path]) = m.sortWith(maxDelayComp).filter(maxDelayExceedsLimit)

    def showPaths(m: List[Path]) = {
        m.foreach { case (n, (ed, sd)) => println(s"$n:\n    end = $ed, start = $sd") }
    }
}

trait TAPArgParser {
    type OptionMap = Map[String, Option[String]]

    val usage = """
        timingAnalysisProcessor
        Usage: mill timing.runMain vme.TAPTest [OPTION...]
            -s, --source   the timing analysis you would like to extract
                           default: none
            -o, --output   the place you want to store your extracted verilog
                           default: $(source).res
            -c, --cycle    the target cycle length
                           default: 0.4(ns)
            -h, --help     print this help info
      """

    def parse(args: List[String]) = {
        def nextOption(map: OptionMap, l: List[String]): OptionMap = {
            def isSwitch(s : String)= (s(0) == '-')
            l match {
                case Nil => map
                case ("--help" | "-h") :: tail => {
                    println(usage)
                    sys.exit()
                    map
                }
                case ("--source" | "-s") :: file :: tail =>
                    nextOption(map ++ Map("source" -> Some(file)), tail)
                case ("--output" | "-o") :: path :: tail =>
                    nextOption(map ++ Map("output" -> Some(path)), tail)
                case ("--cycle" | "-c") :: cycle :: tail =>
                    nextOption(map ++ Map("cycle" -> Some(cycle)), tail)
                // this should always be the last argument, since it is length variable
                case s :: tail => {
                    if (isSwitch(s)) println(s"unexpected argument $s")
                    nextOption(map, tail)
                }
            }
        }
        nextOption(Map("source" -> None, "output" -> None, "cycle" -> None), args)
    }

    

    def wrapParams(args: Array[String]): (String, String, Double) = {
        val argL = args.toList
        val paramMap = parse(argL)
        def noSource = {
            println("you have to specify a timing analysis file!")
            println(usage)
            sys.exit()
            ""
        }
        def delayToDouble(d: String): Double = Try(d.toDouble).getOrElse(0.4)
        val source = paramMap("source").getOrElse(noSource)
        val output = paramMap("output").getOrElse(env("NOOP_HOME")+"/build/extracted/")
        val cycle  = delayToDouble(paramMap("cycle").getOrElse("0.4"))
        (source, output, cycle)
    }
}

object TAPTest extends TAPArgParser {
    def main(args: Array[String]): Unit = {
        val (source, output, cycle) = wrapParams(args) // TODO: output to file
        val tap = new TimingAnalysisParser(cycle)
        val l = tap.makeRecordFromFile(source)
        // tap.showPaths(l)
        println("----------------------Total delay violations------------------------")
        tap.showPaths(tap.sortWithTotalDelay(l))
        println("----------------------Max delay violations------------------------")
        tap.showPaths(tap.sortWithMaxDelay(l))
    }
}