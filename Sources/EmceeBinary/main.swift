import Darwin
import EmceeLib

func main() -> Int32 {
    return Main().main()
}

let exitCode = main()
print("Finished executing with exit code \(exitCode)")
exit(exitCode)
